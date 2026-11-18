#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
deploy.py —— ISEE 报表项目部署同步工具（零第三方 Python 依赖）

设计要点:
  * 优先 rsync：本机存在 rsync、且远端也可用时，直接调用 rsync（输出即 rsync 原生风格）
  * 回退 Python：本机/远端任一没有 rsync 时，用 ssh/scp/tar 做「清单比对 + 增量打包上传」，
    输出风格刻意对齐 rsync（--itemize-changes / --stats）
  * 分层同步：项目文件 / 字体 / isee-core / 第三方 typst 包，按需组合

命令:
  project    只上传项目模板/数据/脚本（不含字体、isee-core、第三方包）
  init       初始化：全量上传 字体 + isee-core + 项目文件 + 第三方包
  packages   只同步第三方 typst 包
  fonts      只同步字体文件
  full       全量上传，并先检测「生产端是否落后当前版本」（git 提交号对比）

通用选项:
  --dry-run     只预览，不实际传输（rsync 用 -n，python 只打印待传清单）
  --delete      删除远端多余文件（默认关闭，避免误删）
  --print-cmd   只打印将要执行的 rsync 命令后退出（调试用）
  --config PATH 指定配置文件（默认脚本同目录的 .deploy.json）

连接信息放在 .deploy.json（见 .deploy.example.json），不写在本文件里。
"""

import argparse
import fnmatch
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile

# ===== 路径常量 =====
HERE = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(HERE, ".deploy.json")
EXAMPLE_FILE = ".deploy.example.json"
VERSION_FILE = ".deploy-version"

# ===== 各层的本地路径与默认远端路径 =====
def local_packages_dir():
    """第三方 typst 包目录：Windows 与 Linux 各取默认位置，可被配置覆盖。"""
    if os.name == "nt":
        base = os.environ.get("LOCALAPPDATA", os.path.join(os.path.expanduser("~"), "AppData", "Local"))
        return os.path.join(base, "typst", "packages", "preview")
    return os.path.join(os.path.expanduser("~"), ".cache", "typst", "packages", "preview")


def layer_specs(cfg):
    """返回 {层名: [(本地目录, 远端目录, 排除列表), ...]}。"""
    root = cfg["remote_dir"].rstrip("/")
    return {
        "project": [
            (HERE, root, [
                ".git", ".gitignore", ".gitmodules", ".vscode", ".agents", ".codebuddy",
                "fonts", "isee-core", "*.pdf", "__pycache__", "*.pyc",
                ".deploy.json", EXAMPLE_FILE, "*.tgz", "out", "output",
            ]),
        ],
        "core": [
            (os.path.join(HERE, "isee-core"), cfg.get("remote_core_dir", root + "/isee-core"), [".git"]),
        ],
        "fonts": [
            (os.path.join(HERE, "fonts"), cfg.get("remote_fonts_dir", root + "/fonts"), ["*.md"]),
        ],
        "packages": [
            (cfg.get("local_packages_dir") or local_packages_dir(),
             cfg.get("remote_pkgs_dir", "~/.cache/typst/packages/preview"), []),
        ],
    }


COMMANDS = {
    "project":  ["project"],
    "init":     ["fonts", "core", "project", "packages"],
    "packages": ["packages"],
    "fonts":    ["fonts"],
    "full":     ["fonts", "core", "project", "packages"],
}

# ===== 工具函数 =====
def shquote(s):
    """单引号包裹 shell 参数（远端命令里用）。"""
    return "'" + str(s).replace("'", "'\\''") + "'"


def remote_quote(path):
    """远端路径引用：开头的 ~ 转成 $HOME 由远端 shell 展开，其余转义后加双引号。"""
    path = str(path)
    if path == "~" or path.startswith("~/"):
        rest = path[2:] if path.startswith("~/") else ""
        for ch, esc in (("\\", "\\\\"), ('"', '\\"'), ("$", "\\$"), ("`", "\\`")):
            rest = rest.replace(ch, esc)
        return '"$HOME/' + rest + '"'
    return shquote(path)


def human(n):
    for unit in ("", "K", "M", "G", "T"):
        if abs(n) < 1024 or unit == "T":
            return "%d%s" % (n, unit) if unit == "" else "%.1f%s" % (n, unit)
        n = n / 1024.0


def emit(line=""):
    print(line, flush=True)


def is_excluded(rel, excludes):
    parts = rel.replace(os.sep, "/").split("/")
    for pat in excludes:
        if fnmatch.fnmatch(rel, pat) or any(fnmatch.fnmatch(p, pat) for p in parts):
            return True
    return False


def run(cmd, **kw):
    return subprocess.run(cmd, **kw)


def ssh_base(cfg):
    return ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=8", cfg["target"]]


# ===== 配置 =====
def load_config(path):
    p = path or CONFIG_FILE
    if not os.path.exists(p):
        emit("错误: 找不到配置文件 %s" % os.path.basename(p))
        emit("  请复制 %s 为 .deploy.json，并填写 target / remote_dir。" % EXAMPLE_FILE)
        sys.exit(2)
    import json
    with open(p, encoding="utf-8") as f:
        cfg = json.load(f)
    for key in ("target", "remote_dir"):
        if not cfg.get(key):
            emit("错误: 配置缺少必填项 '%s'（见 %s）" % (key, EXAMPLE_FILE))
            sys.exit(2)
    return cfg


# ===== rsync 可用性探测 =====
def rsync_usable(cfg):
    """本机有 rsync 且远端也有 rsync 时才返回 True。"""
    if not shutil.which("rsync"):
        return False
    try:
        r = run(ssh_base(cfg) + ["command -v rsync >/dev/null 2>&1"],
                capture_output=True, timeout=15)
        return r.returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


# ===== 版本检测 =====
def local_version():
    try:
        r = run(["git", "-C", HERE, "rev-parse", "--short", "HEAD"], capture_output=True, text=True)
        if r.returncode == 0:
            return r.stdout.strip()
    except OSError:
        pass
    return None


def remote_version(cfg):
    path = remote_quote(cfg["remote_dir"].rstrip("/") + "/" + VERSION_FILE)
    try:
        r = run(ssh_base(cfg) + ["cat %s 2>/dev/null" % path], capture_output=True, text=True, timeout=15)
        return r.stdout.strip() or None if r.returncode == 0 else None
    except (OSError, subprocess.TimeoutExpired):
        return None


def write_version_file():
    v = local_version()
    if v:
        with open(os.path.join(HERE, VERSION_FILE), "w", encoding="utf-8") as f:
            f.write(v + "\n")
    return v


# ===== rsync 引擎 =====
def build_rsync_cmd(cfg, local_dir, remote_dir, excludes, dry_run, delete):
    cmd = ["rsync", "-a", "--itemize-changes", "--stats", "--human-readable"]
    if dry_run:
        cmd.append("--dry-run")
    if delete:
        cmd.append("--delete")
    for pat in excludes:
        cmd.append("--exclude=" + pat)
    src = local_dir.rstrip(os.sep) + os.sep
    dst = "%s:%s/" % (cfg["target"], str(remote_dir).rstrip("/"))
    cmd += [src, dst]
    return cmd


def sync_with_rsync(cfg, layers, dry_run, delete, print_cmd):
    specs = layer_specs(cfg)
    for name in layers:
        for local_dir, remote_dir, excludes in specs[name]:
            cmd = build_rsync_cmd(cfg, local_dir, remote_dir, excludes, dry_run, delete)
            emit("sending incremental file list  [%s]" % name)
            if print_cmd:
                emit("  " + " ".join(shquote(c) for c in cmd))
                continue
            r = run(cmd)
            if r.returncode != 0:
                emit("rsync 失败（%s，退出码 %d）" % (name, r.returncode))
                return r.returncode
    return 0


# ===== Python 回退引擎 =====
def local_manifest(local_dir, excludes):
    result = {}
    if not os.path.isdir(local_dir):
        return result
    for root, dirs, files in os.walk(local_dir):
        rel_dir = os.path.relpath(root, local_dir)
        dirs[:] = [d for d in dirs if not is_excluded(
            "" if rel_dir == "." else rel_dir + "/" + d, excludes)]
        for fn in files:
            full = os.path.join(root, fn)
            rel = fn if rel_dir == "." else rel_dir + "/" + fn
            rel = rel.replace(os.sep, "/")
            if is_excluded(rel, excludes):
                continue
            try:
                st = os.stat(full)
            except OSError:
                continue
            result[rel] = (st.st_size, int(st.st_mtime))
    return result


def remote_manifest(cfg, remote_dir):
    """用一条 find 取远端清单（相对路径、大小、mtime 秒）。目录不存在返回 None。"""
    d = remote_quote(remote_dir)
    script = "test -d %s || exit 2; cd %s && find . -type f -printf '%%P\\t%%s\\t%%T@\\n' 2>/dev/null" % (d, d)
    try:
        r = run(ssh_base(cfg) + [script], capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if r.returncode == 2:
        return None  # 远端目录尚不存在
    out = {}
    for line in r.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        try:
            out[parts[0]] = (int(parts[1]), int(float(parts[2])))
        except ValueError:
            continue
    return out


def diff_manifests(local, remote):
    """返回 (需上传列表, 未变化数量)。远端为 None 表示全量。"""
    if remote is None:
        return sorted(local.keys()), 0
    upload, unchanged = [], 0
    for rel, sig in local.items():
        if remote.get(rel) != sig:
            upload.append(rel)
        else:
            unchanged += 1
    return sorted(upload), unchanged


def sync_with_python(cfg, layers, dry_run, delete):
    specs = layer_specs(cfg)
    target = cfg["target"]
    for name in layers:
        for local_dir, remote_dir, excludes in specs[name]:
            emit("sending incremental file list  [%s]" % name)
            if not os.path.isdir(local_dir):
                emit("  跳过：本地目录不存在 %s" % local_dir)
                continue
            local = local_manifest(local_dir, excludes)
            remote = remote_manifest(cfg, remote_dir)
            upload, unchanged = diff_manifests(local, remote)

            total_bytes = 0
            for rel in upload:
                sig = local[rel]
                total_bytes += sig[0]
                state = "new" if remote is None or rel not in remote else "changed"
                emit("  " + (">f+++++++++ " if state == "new" else ">f..t...... ") + rel)

            if dry_run:
                emit("Number of regular files transferred: %d (dry-run)" % len(upload))
                emit("Total file size: %s" % human(total_bytes))
                continue

            if upload:
                ok = upload_archive(target, local_dir, remote_dir, upload)
                if not ok:
                    return 1

            if delete and remote is not None:
                remove_orphans(cfg, remote_dir, set(local), set(remote))

            emit("Number of regular files transferred: %d" % len(upload))
            emit("Total file size: %s" % human(total_bytes))
            emit("Unchanged files skipped: %d" % unchanged)
    return 0


def upload_archive(target, local_dir, remote_dir, files):
    """把变化文件打成一个 tgz，一次 scp，远端解包 —— N 个小文件 = 1 次连接。"""
    fd, tmp = tempfile.mkstemp(suffix=".tgz")
    os.close(fd)
    try:
        with tarfile.open(tmp, "w:gz") as tf:
            for rel in files:
                tf.add(os.path.join(local_dir, rel.replace("/", os.sep)), arcname=rel)
        remote_tmp = "/tmp/.isee-deploy-%d.tgz" % os.getpid()
        scp = run(["scp", "-q", tmp, "%s:%s" % (target, remote_tmp)])
        if scp.returncode != 0:
            emit("  scp 失败（退出码 %d）" % scp.returncode)
            return False
        rdir = remote_quote(remote_dir)
        extract = "mkdir -p %s && tar xzf %s -C %s && rm -f %s" % (rdir, shquote(remote_tmp), rdir, shquote(remote_tmp))
        ext = run(["ssh", "-o", "BatchMode=yes", target, extract])
        if ext.returncode != 0:
            emit("  远端解包失败（退出码 %d）" % ext.returncode)
            return False
        return True
    finally:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def remove_orphans(cfg, remote_dir, local_names, remote_names):
    """删除远端存在、本地不存在的文件（--delete）。"""
    orphans = sorted(remote_names - local_names)
    if not orphans:
        return
    for rel in orphans:
        emit("  *deleting   " + rel)
    rdir = remote_quote(remote_dir)
    script = "cd %s && rm -f -- %s" % (rdir, " ".join(shquote(o) for o in orphans))
    run(ssh_base(cfg) + [script])


# ===== 版本检测报告 =====
def report_version(cfg):
    local_v = local_version()
    remote_v = remote_version(cfg)
    emit("=== 版本检测 ===")
    emit("  本地版本: %s" % (local_v or "未知（非 git 仓库？）"))
    if remote_v is None:
        emit("  生产版本: 无标记（可能首次部署）")
    elif remote_v == local_v:
        emit("  生产版本: %s  —— 已是当前版本" % remote_v)
    else:
        emit("  生产版本: %s  —— 生产端落后于当前版本 %s" % (remote_v, local_v or "?"))
    emit()
    return local_v


# ===== 主流程 =====
def main():
    parser = argparse.ArgumentParser(description="ISEE 报表项目部署同步工具")
    parser.add_argument("command", choices=list(COMMANDS) + ["selftest"], help="要执行的命令")
    parser.add_argument("--dry-run", action="store_true", help="只预览，不实际传输")
    parser.add_argument("--delete", action="store_true", help="删除远端多余文件")
    parser.add_argument("--print-cmd", action="store_true", help="只打印 rsync 命令后退出")
    parser.add_argument("--config", help="配置文件路径")
    args = parser.parse_args()

    if args.command == "selftest":
        return selftest()

    cfg = load_config(args.config)
    layers = COMMANDS[args.command]

    emit("=== ISEE 部署同步 [%s] ===" % args.command)
    emit("  目标: %s:%s" % (cfg["target"], cfg["remote_dir"]))

    if args.command in ("init", "full"):
        write_version_file()
    if args.command == "full":
        report_version(cfg)

    use_rsync = not args.print_cmd and rsync_usable(cfg)
    emit("  引擎: %s" % ("rsync" if use_rsync else "python (ssh/scp/tar)"))
    emit()

    if use_rsync:
        rc = sync_with_rsync(cfg, layers, args.dry_run, args.delete, False)
    else:
        if args.print_cmd:
            emit("（--print-cmd 仅对 rsync 引擎有效；当前走 python 引擎）")
        rc = sync_with_python(cfg, layers, args.dry_run, args.delete)

    emit()
    emit("完成。" if rc == 0 else "存在错误，退出码 %d" % rc)
    return rc


# ===== 自测（不依赖网络） =====
def selftest():
    emit("=== selftest ===")
    tmp = tempfile.mkdtemp(prefix="isee-deploy-test-")
    try:
        os.makedirs(os.path.join(tmp, "sub"))
        open(os.path.join(tmp, "a.txt"), "w").write("a")
        open(os.path.join(tmp, "sub", "b.bin"), "w").write("bbb")
        open(os.path.join(tmp, "skip.pdf"), "w").write("x")

        loc = local_manifest(tmp, ["*.pdf", "__pycache__"])
        assert set(loc) == {"a.txt", "sub/b.bin"}, loc
        emit("  local_manifest + excludes: OK")

        up, un = diff_manifests(loc, {"a.txt": loc["a.txt"], "gone.txt": (1, 1)})
        assert up == ["sub/b.bin"] and un == 1, (up, un)
        emit("  diff_manifests (增量/未变): OK")

        up2, un2 = diff_manifests(loc, None)
        assert len(up2) == 2 and un2 == 0
        emit("  diff_manifests (远端不存在=全量): OK")

        cfg = {"target": "user@host", "remote_dir": "~/typst"}
        cmd = build_rsync_cmd(cfg, tmp, "~/typst", [".git", "fonts"], True, False)
        assert cmd[0] == "rsync" and "--dry-run" in cmd and "--exclude=.git" in cmd
        assert cmd[-1] == "user@host:~/typst/" and cmd[-2].endswith(os.sep)
        emit("  build_rsync_cmd: OK")
        emit("    示例: " + " ".join(shquote(c) for c in cmd))

        assert remote_quote("~/typst/x") == '"$HOME/typst/x"', remote_quote("~/typst/x")
        assert remote_quote("/abs/path") == "'/abs/path'"
        emit("  remote_quote (~ and abs): OK")
        emit("selftest 全部通过。")
        return 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
