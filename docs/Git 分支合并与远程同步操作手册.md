（基于 Flutter 项目实战场景，含冲突处理、.gitignore 配置、避坑指南）

## 一、准备工作

### 1. 环境检查

- 确认 Git 已配置用户信息（首次使用）：

  bash

  ```bash
  git config --global user.name "你的用户名"
  git config --global user.email "你的邮箱"
  ```
- 确认当前分支与远程关联正常：

  bash

  ```bash
  git remote -v  # 显示 origin 远程仓库地址，无则执行 git remote add origin 仓库地址
  ```

### 2. 分支命名规范（推荐）

- 主分支：`master`（生产环境）/ `main`
- 功能分支：`feat/功能名称`（如 `feat/dependency-injection`）
- 临时分支：`temp/功能名称`（如 `temp-dependency-injection`）
- 修复分支：`fix/问题描述`（如 `fix/cache-conflict`）

## 二、核心操作流程

### 1. 分支合并（本地）

#### 步骤 1：切换到目标分支（如 master）

```bash
git checkout master  # 或 git switch master
```

#### 步骤 2：拉取目标分支最新代码（避免合并冲突）

```bash
git pull origin master
```

#### 步骤 3：合并源分支（如 temp-dependency-injection）

```bash
git merge temp-dependency-injection
```

- 无冲突：直接合并成功，跳过步骤 4；
- 有冲突：终端提示 `CONFLICT`，进入冲突处理流程。

#### 步骤 4：冲突处理（关键）

##### （1）识别冲突文件

```bash
git status  # 查看标有 "both modified" "deleted by us" "both added" 的文件
```

##### （2）分类处理冲突


| 冲突类型                  | 处理方式                                                                               |
| ------------------------- | -------------------------------------------------------------------------------------- |
| both modified（双向修改） | 打开文件删除冲突标记（`<<<<<<<`/`=======`/`>>>>>>>`），合并有效代码后 `git add 文件名` |
| deleted by us（我方删除） | 保留文件：`git add 文件名`；删除文件：`git rm 文件名`                                  |
| both added（双方新增）    | 直接暂存：`git add 文件名`（无冲突标记，仅需确认保留）                                 |

##### （3）关键提醒

- 冲突标记必须彻底删除，否则 Git 判定冲突未解决；
- 代码合并优先保留核心逻辑（如缓存系统 + 依赖注入功能整合），删除冗余代码。

#### 步骤 5：完成合并提交

git commit  # 自动弹出合并提交信息，保存退出；或自定义信息：git commit -m "合并xxx分支：整合xxx功能"
### 2. 暂存区操作（解决「未暂存 / 未跟踪文件」）

#### （1）暂存修改文件

```bash
git add 文件名  # 单个文件
git add 目录名/  # 批量暂存目录（如 git add lib/ test/）
git add .  # 暂存所有修改（谨慎使用，避免暂存无用文件）
```
#### （2）移除暂存区文件（不删除本地）

bash

```bash
git reset HEAD 文件名/目录名  # 如 git reset HEAD test/
```
#### （3）删除本地未跟踪文件（谨慎）

```bash
rm -rf 文件名/目录名  # 如 rm -rf test_cache_ui/
```
### 3. .gitignore 配置（忽略无用文件）

#### 步骤 1：创建 / 编辑 .gitignore

```bash
code .gitignore  # 用 VSCode 打开，无则自动创建
```
#### 步骤 2：Flutter 项目通用配置（直接复制）

```bash
# 编译产物
build/
.dart_tool/
.pub/
.flutter-plugins
.flutter-plugins-dependencies

# 测试相关
test/
test_cache_ui/
*.test.dart.bak

# 临时文件
lib/src/core/cache/enhanced_hive_cache_manager.dart
*.hive
*.lock

# IDE 配置
.idea/
.vscode/
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# 系统文件
.DS_Store
Thumbs.db
```
#### 步骤 3：使 .gitignore 生效（关键）

- 新增规则后，移除已跟踪的文件记录（如 test/ 目录）：

  bash

  ```bash
  git rm --cached -r test/  # -r 递归处理目录
  ```
- 提交 .gitignore 配置：

  bash

  ```bash
  git add .gitignore
  git commit -m "gitignore: 配置忽略测试目录、临时文件等"
  ```

### 4. 远程同步（推送本地代码）

#### 步骤 1：拉取远程最新代码（避免推送冲突）

bash

```bash
git pull origin master
```
#### 步骤 2：推送本地提交

bash

```bash
git push origin master
```
#### 步骤 3：跳过预推送钩子（解决推送卡住）

若推送时触发代码检查 / 测试阻塞，用 `--no-verify` 跳过：

bash

```bash
git push origin master --no-verify
```
## 三、常见问题处理

### 1. 提交失败：「unmerged files」

- 原因：冲突文件未彻底解决（残留冲突标记）；
- 解决：重新打开 `git status` 提示的 `U` 标记文件，搜索并删除 `<<<<<<<` 等标记，执行 `git add 文件名` 后重新提交。

### 2. 推送卡住：「quick test check」无反应

- 原因：预推送钩子（.git/hooks/pre-push）执行测试检查阻塞；
- 解决：终止 `git.exe`/`dart.exe` 进程（任务管理器），用 `git push --no-verify` 跳过。

### 3. 警告：「CRLF will be replaced by LF」

- 原因：Windows 与 Unix 系统换行符不一致，Git 自动转换；
- 处理：无需操作（无害），或配置 Git 自动适配：

  bash

  ```bash
  git config --global core.autocrlf true
  ```

### 4. 误操作回滚

- 合并失败回滚：`git merge --abort`；
- 提交后回滚（未推送）：`git reset --hard HEAD~1`（回滚到上一个提交，谨慎使用）；
- 推送后回滚：不建议直接回滚，可创建修复分支处理。

## 四、常用命令速查


| 功能                   | 命令                                                               |
| ---------------------- | ------------------------------------------------------------------ |
| 查看分支状态           | git status                                                         |
| 查看提交记录           | git log --oneline -n 5（显示最新 5 条）                            |
| 切换分支               | git checkout 分支名 /git switch 分支名                             |
| 创建并切换分支         | git checkout -b 新分支名                                           |
| 删除本地分支（合并后） | git branch -d 分支名（如 git branch -d temp-dependency-injection） |
| 强制删除本地分支       | git branch -D 分支名（未合并分支）                                 |
| 拉取远程分支           | git pull origin 分支名                                             |
| 推送本地分支           | git push origin 分支名                                             |
| 查看远程分支           | git branch -r                                                      |

## 五、操作原则

1. 合并前必拉取：合并分支、推送代码前，先执行 `git pull` 同步最新代码；
2. 冲突早处理：合并时出现冲突，优先解决核心文件（如 lib/main.dart），再处理文档 / 配置文件；
3. 提交要清晰：每次提交信息需说明核心操作（如「合并 xxx 分支：整合依赖注入 + 缓存功能」）；
4. 主分支稳定：`master` 分支仅用于合并已测试的功能，避免直接在主分支开发。
