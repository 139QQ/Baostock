#!/usr/bin/env python3
"""
基速文档自动生成器
用于自动生成和更新项目文档

作者: 开发团队
版本: v1.0
日期: 2025-10-30
"""

import os
import sys
import json
import yaml
import argparse
import logging
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional
import re

try:
    from jinja2 import Environment, FileSystemLoader, Template
    import markdown
except ImportError as e:
    print(f"❌ 缺少依赖库: {e}")
    print("请运行: pip install jinja2 pyyaml markdown")
    sys.exit(1)

class DocGenerator:
    """文档自动生成器"""

    def __init__(self, project_root: str = "."):
        self.project_root = Path(project_root).resolve()
        self.docs_dir = self.project_root / "docs"
        self.setup_logging()
        self.config = self.load_config()
        self.setup_jinja_env()

    def setup_logging(self):
        """设置日志"""
        log_level = "INFO"  # 默认日志级别
        logging.basicConfig(
            level=getattr(logging, log_level),
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)

        # 配置文件加载后再设置文件日志
        if hasattr(self, 'config') and self.config:
            log_file = self.config.get("notifications", {}).get("log_file", ".docs-automation.log")
            file_handler = logging.FileHandler(self.project_root / log_file)
            self.logger.addHandler(file_handler)

    def setup_jinja_env(self):
        """设置Jinja2环境"""
        template_dir = self.project_root / self.config.get("templates", {}).get("dir", ".docs-templates")

        if not template_dir.exists():
            template_dir.mkdir(parents=True, exist_ok=True)
            self.logger.info(f"创建模板目录: {template_dir}")

        self.jinja_env = Environment(
            loader=FileSystemLoader(str(template_dir)),
            autoescape=False,
            trim_blocks=True,
            lstrip_blocks=True
        )

        # 添加自定义过滤器
        self.jinja_env.filters['datetime'] = self.format_datetime
        self.jinja_env.filters['filesize'] = self.format_filesize

    def load_config(self) -> Dict[str, Any]:
        """加载文档配置"""
        config_file = self.project_root / ".docs-config.yaml"

        if config_file.exists():
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    config = yaml.safe_load(f)
                self.logger.info(f"配置文件加载成功: {config_file}")
                return config
            except Exception as e:
                self.logger.error(f"配置文件加载失败: {e}")

        self.logger.warning("使用默认配置")
        return self.default_config()

    def default_config(self) -> Dict[str, Any]:
        """默认配置"""
        return {
            "project": {
                "name": "基速基金量化分析平台",
                "version": "v4.0",
                "description": "专业的基金量化分析平台"
            },
            "modules": {},
            "output": {
                "format": ["markdown"],
                "encoding": "utf-8"
            },
            "generation": {
                "auto_index": True,
                "auto_toc": True,
                "auto_sync": True
            }
        }

    def parse_chapter_info(self, file_path: Path) -> Dict[str, str]:
        """解析章节信息"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # 提取标题和描述
            title = ""
            description = ""

            lines = content.split('\n')
            for i, line in enumerate(lines):
                if line.startswith('# ') and not title:
                    title = line[2:].strip()
                elif line.startswith('## ') and not description:
                    description = line[3:].strip()
                elif title and description:
                    break

            return {
                "file": file_path.name,
                "title": title or file_path.stem,
                "description": description or "章节描述",
                "path": f"./{file_path.name}",
                "size": file_path.stat().st_size,
                "modified": datetime.fromtimestamp(file_path.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S")
            }
        except Exception as e:
            self.logger.error(f"解析章节信息失败 {file_path}: {e}")
            return {
                "file": file_path.name,
                "title": file_path.stem,
                "description": "解析失败",
                "path": f"./{file_path.name}",
                "size": 0,
                "modified": "未知"
            }

    def generate_prd_index(self) -> bool:
        """生成PRD文档索引"""
        prd_config = self.config.get("modules", {}).get("prd", {})
        if not prd_config.get("enabled", True):
            return False

        prd_dir = self.docs_dir / prd_config["path"]
        if not prd_dir.exists():
            self.logger.warning(f"PRD目录不存在: {prd_dir}")
            return False

        chapters = []
        chapter_files = prd_config.get("chapters", [])

        # 如果配置中有章节列表，按配置顺序
        if chapter_files:
            for chapter_file in chapter_files:
                file_path = prd_dir / chapter_file["file"]
                if file_path.exists():
                    chapter_info = self.parse_chapter_info(file_path)
                    chapter_info.update(chapter_file)
                    chapters.append(chapter_info)
        else:
            # 否则扫描所有markdown文件
            for file_path in sorted(prd_dir.glob("*.md")):
                if file_path.name != "index.md":
                    chapter_info = self.parse_chapter_info(file_path)
                    chapters.append(chapter_info)

        # 渲染索引模板
        template_content = self.get_prd_index_template()
        template = Template(template_content)

        content = template.render(
            chapters=chapters,
            config=self.config,
            prd_config=prd_config,
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            generator_info={
                "version": "v1.0",
                "author": "文档自动化系统"
            }
        )

        # 写入索引文件
        index_file = prd_dir / "index.md"

        # 备份原文件
        if self.config.get("generation", {}).get("backup_original", True) and index_file.exists():
            backup_file = index_file.with_suffix(f".md.backup.{int(datetime.now().timestamp())}")
            index_file.rename(backup_file)
            self.logger.info(f"原文件已备份: {backup_file}")

        with open(index_file, 'w', encoding='utf-8') as f:
            f.write(content)

        self.logger.info(f"PRD索引已生成: {index_file}")
        return True

    def generate_architecture_index(self) -> bool:
        """生成架构文档索引"""
        arch_config = self.config.get("modules", {}).get("architecture", {})
        if not arch_config.get("enabled", True):
            return False

        arch_dir = self.docs_dir / arch_config["path"]
        if not arch_dir.exists():
            self.logger.warning(f"架构目录不存在: {arch_dir}")
            return False

        chapters = []
        chapter_files = arch_config.get("chapters", [])

        # 如果配置中有章节列表，按配置顺序
        if chapter_files:
            for chapter_file in chapter_files:
                file_path = arch_dir / chapter_file["file"]
                if file_path.exists():
                    chapter_info = self.parse_chapter_info(file_path)
                    chapter_info.update(chapter_file)
                    chapters.append(chapter_info)
        else:
            # 否则扫描所有markdown文件
            for file_path in sorted(arch_dir.glob("*.md")):
                if file_path.name != "index.md":
                    chapter_info = self.parse_chapter_info(file_path)
                    chapters.append(chapter_info)

        # 渲染索引模板
        template_content = self.get_architecture_index_template()
        template = Template(template_content)

        content = template.render(
            chapters=chapters,
            config=self.config,
            arch_config=arch_config,
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            generator_info={
                "version": "v1.0",
                "author": "文档自动化系统"
            }
        )

        # 写入索引文件
        index_file = arch_dir / "index.md"

        # 备份原文件
        if self.config.get("generation", {}).get("backup_original", True) and index_file.exists():
            backup_file = index_file.with_suffix(f".md.backup.{int(datetime.now().timestamp())}")
            index_file.rename(backup_file)
            self.logger.info(f"原文件已备份: {backup_file}")

        with open(index_file, 'w', encoding='utf-8') as f:
            f.write(content)

        self.logger.info(f"架构索引已生成: {index_file}")
        return True

    def generate_main_index(self) -> bool:
        """生成主文档索引"""
        modules = []

        # V4标准化文档
        v4_docs = {
            "title": "🚀 V4标准化文档 (最新)",
            "description": "符合BMad V4标准的完整文档体系",
            "items": [
                {
                    "title": "V4文档标准化报告",
                    "path": "./V4_DOCUMENTATION_STANDARDIZATION_REPORT.md",
                    "description": "完整的V4文档标准化整理报告"
                },
                {
                    "title": "PRD产品需求文档",
                    "path": "./prd.md",
                    "description": "完整的产品需求概述文档"
                },
                {
                    "title": "架构设计文档",
                    "path": "./architecture/index.md",
                    "description": "完整的系统架构设计文档"
                },
                {
                    "title": "用户故事文档",
                    "path": "./stories/index.md",
                    "description": "详细的用户故事概览和指南"
                },
                {
                    "title": "QA测试文档",
                    "path": "./qa/测试文档.md",
                    "description": "完整的质量保证测试体系"
                }
            ]
        }
        modules.append(v4_docs)

        # 扫描其他文档
        root_docs = []
        for file_path in sorted(self.docs_dir.glob("*.md")):
            if file_path.name not in ["index.md", "V4_DOCUMENTATION_STANDARDIZATION_REPORT.md", "prd.md"]:
                root_docs.append({
                    "title": file_path.stem,
                    "path": f"./{file_path.name}",
                    "description": self.get_file_description(file_path)
                })

        if root_docs:
            modules.append({
                "title": "📚 项目文档",
                "description": "项目相关的技术文档和设计文档",
                "items": root_docs
            })

        # 渲染主索引模板
        template_content = self.get_main_index_template()
        template = Template(template_content)

        content = template.render(
            modules=modules,
            config=self.config,
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            generator_info={
                "version": "v1.0",
                "author": "文档自动化系统"
            }
        )

        # 写入主索引文件
        index_file = self.docs_dir / "index.md"

        # 备份原文件
        if self.config.get("generation", {}).get("backup_original", True) and index_file.exists():
            backup_file = index_file.with_suffix(f".md.backup.{int(datetime.now().timestamp())}")
            index_file.rename(backup_file)
            self.logger.info(f"原文件已备份: {backup_file}")

        with open(index_file, 'w', encoding='utf-8') as f:
            f.write(content)

        self.logger.info(f"主索引已生成: {index_file}")
        return True

    def get_file_description(self, file_path: Path) -> str:
        """获取文件描述"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # 提取第一段作为描述
            lines = content.split('\n')
            for line in lines:
                line = line.strip()
                if line and not line.startswith('#') and not line.startswith('!'):
                    return line[:100] + "..." if len(line) > 100 else line

            return "文档描述"
        except:
            return "无法读取描述"

    def check_links(self) -> bool:
        """检查文档链接"""
        if not self.config.get("quality", {}).get("check_links", True):
            return True

        self.logger.info("开始检查文档链接...")

        all_md_files = list(self.docs_dir.rglob("*.md"))
        broken_links = []

        for md_file in all_md_files:
            try:
                with open(md_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                # 查找markdown链接
                links = re.findall(r'\[([^\]]+)\]\(([^)]+)\)', content)

                for link_text, link_url in links:
                    if link_url.startswith('./') or link_url.startswith('../'):
                        # 相对链接
                        target_path = (md_file.parent / link_url).resolve()
                        if not target_path.exists():
                            broken_links.append({
                                "file": str(md_file.relative_to(self.project_root)),
                                "link": link_url,
                                "text": link_text
                            })
            except Exception as e:
                self.logger.error(f"检查链接失败 {md_file}: {e}")

        if broken_links:
            self.logger.error(f"发现 {len(broken_links)} 个失效链接:")
            for link in broken_links:
                self.logger.error(f"  - {link['file']}: {link['link']} ({link['text']})")
            return False
        else:
            self.logger.info("所有链接检查通过")
            return True

    def generate_all(self) -> bool:
        """生成所有文档"""
        self.logger.info("开始生成文档...")

        success = True

        if self.config.get("generation", {}).get("auto_index", True):
            success &= self.generate_prd_index()
            success &= self.generate_architecture_index()
            success &= self.generate_main_index()

        # 检查链接
        if success and self.config.get("quality", {}).get("check_links", True):
            self.check_links()

        if success:
            self.logger.info("文档生成完成!")
        else:
            self.logger.error("文档生成失败!")

        return success

    # 模板方法
    def get_prd_index_template(self) -> str:
        """PRD索引模板"""
        return """# PRD 文档索引

## 📋 产品需求文档导航

欢迎来到{{ config.project.name }}的产品需求文档(PRD)分片索引页面。

---

## 📖 文档章节

### 核心需求章节

{% for chapter in chapters %}
{{ loop.index }}. **[{{ chapter.title }}](./{{ chapter.file }})**
   - {{ chapter.description }}
   {% if chapter.size %}   - 文件大小: {{ chapter.size }} bytes{% endif %}
   {% if chapter.modified %}   - 最后更新: {{ chapter.modified }}{% endif %}

{% endfor %}

---

## 🔗 相关文档

- **[主PRD文档](../prd.md)** - 完整的产品需求概述
- **[系统架构文档](../architecture/index.md)** - 技术架构设计
- **[用户故事文档](../stories/index.md)** - 详细开发任务
- **[QA质量文档](../qa/index.md)** - 测试和质量保证

---

## 📝 文档维护

- **文档版本**: {{ config.project.version }}
- **最后更新**: {{ generated_at }}
- **维护团队**: 产品团队
- **更新频率**: 每个迭代周期

---

## 💡 阅读建议

1. **产品团队**: 重点阅读目标背景、需求说明、验收标准
2. **开发团队**: 重点阅读需求说明、技术假设、史诗列表
3. **设计团队**: 重点阅读UI设计目标、需求说明
4. **测试团队**: 重点阅读验收标准、风险约束、需求说明

---

*如需编辑特定章节，请直接导航到对应的分片文件*

---

*🤖 本文档由{{ generator_info.author }}自动生成 (版本: {{ generator_info.version }})*
*📅 生成时间: {{ generated_at }}*
"""

    def get_architecture_index_template(self) -> str:
        """架构索引模板"""
        return """# 系统架构文档索引

## 🏗️ 架构文档导航

欢迎来到{{ config.project.name }}的系统架构文档索引页面。

---

## 📖 架构章节

### 核心架构章节

{% for chapter in chapters %}
{{ loop.index }}. **[{{ chapter.title }}](./{{ chapter.file }})**
   - {{ chapter.description }}
   {% if chapter.size %}   - 文件大小: {{ chapter.size }} bytes{% endif %}
   {% if chapter.modified %}   - 最后更新: {{ chapter.modified }}{% endif %}

{% endfor %}

---

## 🔗 相关文档

- **[主架构文档](../architecture.md)** - 完整的架构设计概述
- **[PRD产品文档](../prd/index.md)** - 产品需求和功能定义
- **[用户故事文档](../stories/index.md)** - 详细开发任务
- **[API接口文档](../akshare_fund_api_parameters.md)** - AKShare基金API接口规范

---

## 📝 文档维护

- **文档版本**: {{ config.project.version }}
- **最后更新**: {{ generated_at }}
- **维护团队**: 架构团队
- **更新频率**: 架构变更时
- **完成状态**: ✅ 全部{{ chapters|length }}章节已完成

---

## 💡 阅读建议

1. **开发团队**: 重点阅读架构概述、技术栈、系统设计
2. **运维团队**: 重点阅读部署架构、灾备方案、监控方案
3. **产品团队**: 重点阅读架构概述、扩展性设计、技术演进
4. **测试团队**: 重点阅读安全架构、性能优化、风险评估

---

## 🎯 架构原则

本系统架构遵循以下核心原则：

- **简单性**: 保持架构简单明了，避免过度设计
- **可扩展性**: 支持业务增长和技术演进
- **高可用性**: 确保系统稳定可靠运行
- **安全性**: 全方位的安全防护措施
- **性能**: 优化的数据处理和响应速度

---

*如需编辑特定章节，请直接导航到对应的分片文件*

---

*🤖 本文档由{{ generator_info.author }}自动生成 (版本: {{ generator_info.version }})*
*📅 生成时间: {{ generated_at }}*
"""

    def get_main_index_template(self) -> str:
        """主索引模板"""
        return """# Documentation Index

本文档索引包含了{{ config.project.name }}的所有技术文档、设计文档和项目规划文档。

{% for module in modules %}
---

## {{ module.title }}

{{ module.description }}

{% for item in module.items %}
### [{{ item.title }}]({{ item.path }})

{{ item.description }}

{% endfor %}

{% endfor %}

---

## 文档使用指南

### 快速开始
1. **产品规划**: 参考 [PRD产品需求文档](./prd.md)
2. **技术架构**: 查看 [架构设计文档](./architecture/index.md)
3. **开发任务**: 阅读 [用户故事文档](./stories/index.md)
4. **质量保证**: 遵循 [QA测试文档](./qa/测试文档.md)

### 文档状态
- **最后更新**: {{ generated_at }}
- **文档版本**: {{ config.project.version }}
- **维护状态**: 活跃维护中

### 文档规范
所有文档遵循以下规范：
- 使用中文编写，技术术语可保留英文
- 包含版本信息和最后更新日期
- 提供足够的示例代码和图表
- 建立交叉引用，便于导航

如需更新或补充文档，请遵循现有格式并更新此索引文件。

---

## 🤖 自动化信息

- **生成器**: {{ generator_info.author }}
- **版本**: {{ generator_info.version }}
- **生成时间**: {{ generated_at }}

---

*本文档索引由文档自动化系统维护，确保所有链接和信息的准确性。*
"""

    # 自定义过滤器
    def format_datetime(self, value, format='%Y-%m-%d %H:%M:%S'):
        """格式化日期时间"""
        if isinstance(value, str):
            return value
        return value.strftime(format)

    def format_filesize(self, size):
        """格式化文件大小"""
        try:
            for unit in ['B', 'KB', 'MB', 'GB']:
                if size < 1024:
                    return f"{size:.1f} {unit}"
                size /= 1024
            return f"{size:.1f} TB"
        except:
            return "未知大小"


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="基速文档自动生成器")
    parser.add_argument("--action", choices=["generate", "check", "sync"],
                       default="generate", help="执行的操作")
    parser.add_argument("--project-root", default=".", help="项目根目录")
    parser.add_argument("--verbose", "-v", action="store_true", help="详细输出")

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    try:
        generator = DocGenerator(args.project_root)

        if args.action == "generate":
            success = generator.generate_all()
        elif args.action == "check":
            success = generator.check_links()
        elif args.action == "sync":
            success = generator.generate_all() and generator.check_links()

        sys.exit(0 if success else 1)

    except Exception as e:
        print(f"ERROR: 执行失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()