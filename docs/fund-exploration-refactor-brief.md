# Project Brief: 基金探索界面重构

## Executive Summary

本项目的核心是重构当前基金探索界面，解决用户"眼睛不知道往哪里看"和"应该先点哪里"的困惑问题。通过信息层次重组、智能推荐优化和折叠式交互设计，为用户提供"主体明确、简洁简单"的基金发现和对比体验。

## Problem Statement

### 当前状态痛点
- **视觉混乱**: 三栏布局（左侧导航+中间内容+右侧工具）导致用户注意力分散
- **导航困惑**: 功能堆叠（搜索、筛选、对比、计算器）缺乏清晰的引导路径
- **推荐价值不足**: 缺乏有吸引力的推荐信息（如"涨20%"的收益率突出展示）
- **决策支持不足**: 对比功能缺乏用户最关心的风险等级和手续费信息

### 问题影响
- 用户无法快速找到目标基金
- 界面信息过载导致选择困难
- 缺乏清晰的行动指引
- 决策效率低下

## Proposed Solution

### 核心设计理念
**"主体明确 + 折叠组织 + 智能推荐 + 简洁交互"**

### 解决方案要点
1. **信息层次重构**: 将当前三栏布局改为主次分明的单栏布局
2. **折叠式交互**: 非核心功能通过折叠/展开方式组织
3. **智能推荐突出**: 以收益率为核心的有吸引力的推荐展示
4. **简化导航**: 明确的用户行动路径指引

### 关键差异化
- 从"功能展示"转向"用户需求引导"
- 从"信息堆叠"转向"价值突出"
- 从"多栏复杂"转向"折叠简洁"

## Target Users

### Primary User Segment: 新手投资者
- **特征**: 缺乏基金投资经验，需要明确指引
- **需求**: 简单易懂的推荐，清晰的操作路径
- **痛点**: 面对大量信息无从下手
- **目标**: 快速找到适合自己的基金产品

### Secondary User Segment: 对比型投资者
- **特征**: 喜欢比较分析多个基金产品
- **需求**: 高效的对比工具，详细的费用和风险信息
- **痛点**: 当前对比功能信息不够全面
- **目标**: 做出最优的基金选择决策

## Goals & Success Metrics

### Business Objectives
- 提升用户基金探索停留时间30%
- 提高基金对比功能使用率50%
- 降低页面跳出率25%
- 提升用户操作成功率（找到目标基金）40%

### User Success Metrics
- 用户能在10秒内理解界面主要功能
- 用户能在3次点击内找到目标基金
- 对比功能使用完成率达到85%
- 用户满意度评分4.5/5

### Key Performance Indicators (KPIs)
- **发现效率**: 从进入页面到找到目标基金的平均时间 < 30秒
- **对比深度**: 用户平均对比基金数量 ≥ 2只
- **功能使用**: 折叠面板的打开率 ≥ 60%
- **任务完成**: 基金搜索/查看详情的完成率 ≥ 80%

## MVP Scope

### Core Features (Must Have)
- **主界面重构**: 简化为单栏主体明确的布局
- **智能折叠系统**: 非核心功能可折叠展开
- **收益率突出推荐**: 基于收益率的醒目推荐展示
- **简化搜索流程**: 一步到位的搜索体验
- **核心对比功能**: 基金关键指标（收益率、风险、手续费）对比

### Out of Scope for MVP
- 个性化推荐算法
- 复杂的数据可视化图表
- 高级筛选条件
- 社交分享功能
- 基金组合管理

### MVP Success Criteria
- 用户能在5个功能模块中明确主次关系
- 折叠面板使用率达到预期目标
- 推荐信息点击率提升明显
- 用户反馈界面"清晰易懂"

## Post-MVP Vision

### Phase 2 Features
- 个性化推荐系统
- 可视化对比工具
- 基金评分体系
- 收益计算器集成

### Long-term Vision
构建智能化的基金投资决策平台，为用户提供从发现、研究到投资的全流程支持。

## Technical Considerations

### Platform Requirements
- **Target Platforms**: Flutter (Web/Desktop/Mobile)
- **Browser/OS Support**: 主流浏览器和移动系统
- **Performance Requirements**: 页面加载时间 < 2秒

### Technology Preferences
- **Frontend**: Flutter/Dart
- **Backend**: 现有API服务
- **UI Framework**: Material Design 3.0
- **State Management**: BLoC/Cubit

### Architecture Considerations
- 保持现有功能模块独立性
- 优化组件层次结构
- 改进响应式布局策略

## Constraints & Assumptions

### Constraints
- **Timeline**: 基于现有功能重构，非全新开发
- **Resources**: 保持当前开发团队规模
- **Technical**: 必须兼容现有API和数据结构
- **Compatibility**: 确保移动端体验不下降

### Key Assumptions
- 用户更关注简洁性而非功能丰富度
- 收益率是最吸引用户的推荐指标
- 折叠式交互能降低界面复杂度
- 单栏布局更适合用户浏览习惯

## Risks & Open Questions

### Key Risks
- **功能简化风险**: 过度简化可能影响专业用户使用
- **信息密度风险**: 折叠可能导致重要信息被忽略
- **用户习惯风险**: 改变现有布局可能需要用户适应期

### Open Questions
- 哪些功能应该默认展开，哪些应该折叠？
- 如何平衡简洁性与功能完整性？
- 新界面是否会影响现有用户的使用习惯？

### Areas Needing Further Research
- 用户对不同布局方案的偏好测试
- 折叠面板的最佳交互方式验证
- 推荐信息展示效果的用户反馈收集

## Next Steps

### Immediate Actions
1. 创建低保真原型设计方案
2. 进行用户可用性测试验证
3. 制定详细的技术实施计划
4. 确定MVP功能优先级排序

### PM Handoff
This Project Brief provides the full context for 基金探索界面重构. Please start in 'PRD Generation Mode', review the brief thoroughly to work with the user to create the PRD section by section as the template indicates, asking for any necessary clarification or suggesting improvements.