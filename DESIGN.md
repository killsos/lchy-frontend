# 系统设计文档 (DESIGN.md)

## 项目概述

### 项目名称
ROI趋势分析仪表板

### 项目描述
这是一个基于Vue 3的现代化数据可视化应用，专注于展示多时间维度的ROI（投资回报率）趋势分析。应用提供丰富的数据筛选功能和响应式图表展示，支持移动端和桌面端。

### 核心功能
- 多维度ROI数据可视化
- 动态数据筛选（应用、国家、出价类型）
- 移动平均值与原始数据切换
- 线性与对数坐标轴
- 响应式设计（移动端/平板/桌面）
- 实时数据同步

## 技术架构

### 技术栈
- **前端框架**: Vue 3 (Composition API)
- **构建工具**: Vite
- **语言**: TypeScript
- **状态管理**: Pinia
- **UI框架**: Element Plus + Tailwind CSS
- **图表库**: ECharts
- **HTTP客户端**: Axios
- **路由**: Vue Router

### 项目结构
```
frontend-project/
├── src/
│   ├── api/              # API接口层
│   │   ├── httpURL.ts    # API端点配置
│   │   ├── index.ts      # API方法封装
│   │   └── request.ts    # HTTP请求配置
│   ├── assets/           # 静态资源
│   │   ├── images/       # 图片资源
│   │   └── styles/       # 样式文件
│   ├── components/       # 可复用组件
│   │   ├── ControlItem.vue    # 控制项组件
│   │   ├── ROIChart.vue       # ROI图表组件
│   │   ├── SelectArea.vue     # 选择区域组件
│   │   └── TopTitle.vue       # 顶部标题组件
│   ├── constants/        # 常量配置
│   │   └── index.ts      # 应用常量
│   ├── pages/           # 页面组件
│   │   └── HomeView.vue  # 主页面
│   ├── router/          # 路由配置
│   │   └── index.ts     # 路由定义
│   ├── stores/          # 状态管理
│   │   ├── chart.ts     # 图表数据状态
│   │   ├── display.ts   # 显示选项状态
│   │   └── filters.ts   # 筛选器状态
│   ├── types/           # TypeScript类型定义
│   │   └── index.ts     # 全局类型
│   └── utils/           # 工具函数
│       └── index.ts     # 通用工具方法
├── public/              # 公共资源
├── docker/              # Docker配置
├── nginx/               # Nginx配置
└── 配置文件...
```

## 设计模式与架构原则

### 1. 组件化设计
- **单一职责**: 每个组件专注于特定功能
- **可复用性**: 组件设计考虑复用场景
- **组合式API**: 使用Vue 3 Composition API提高代码复用

### 2. 状态管理架构
采用Pinia进行集中式状态管理，分离关注点：

#### stores/filters.ts
- 管理筛选器数据（应用名称、国家、出价类型）
- 处理筛选器联动逻辑
- 提供默认值设置

#### stores/chart.ts  
- 管理图表数据（X轴时间、Y轴ROI数据）
- 处理数据获取和更新
- 与API层交互

#### stores/display.ts
- 管理显示选项（移动平均值/原始数据）
- Y轴刻度类型（线性/对数）
- UI展示状态

### 3. 响应式设计策略
```css
/* 断点设计 */
- 移动端: < 768px (单列布局)
- 平板端: 768px - 1280px (2x2网格)  
- 桌面端: >= 1280px (4列网格)
```

## 核心组件设计

### 1. HomeView.vue (主页面)
**职责**: 页面布局和数据流协调
- 响应式布局管理
- 组件状态协调
- 事件处理分发

**关键特性**:
- 三种布局模式适配
- Pinia状态集成
- 生命周期数据初始化

### 2. ROIChart.vue (图表组件)
**职责**: 数据可视化核心
- ECharts图表渲染
- 响应式图表配置
- 数据处理和展示

**关键特性**:
- 支持线性/对数坐标轴
- 移动平均值计算
- 缩放和工具栏功能
- 性能优化（ResizeObserver）

### 3. SelectArea.vue (选择组件)
**职责**: 数据筛选器
- 下拉选择功能
- 双向数据绑定
- 选项动态加载

### 4. ControlItem.vue (控制组件)
**职责**: 显示模式控制
- 单选按钮组
- 视觉反馈（下划线动画）
- 状态同步

## 数据流设计

### 1. 数据流向
```
API Layer → Stores → Components → UI
    ↑                               ↓
    └─── User Actions ←─────────────┘
```

### 2. 核心数据流
```typescript
// 初始化流程
1. HomeView.onMounted() 
2. → filtersStore.loadFilters()
3. → chartStore.initData()
4. → 组件响应式更新

// 筛选器变更流程  
1. 用户选择 → SelectArea.emit()
2. → HomeView.handler() → Store.update()
3. → API请求 → 数据更新 → 图表重渲染
```

### 3. 状态同步策略
- 使用Pinia的`storeToRefs`保持响应性
- 监听器模式处理副作用
- 统一的错误处理机制

## API设计

### 接口规范
```typescript
// 筛选器数据
GET /filters → FiltersResponse
interface FiltersResponse {
  app_names: string[]
  bid_types: string[]  
  countries: string[]
}

// 应用筛选
GET /filteByAppName?appname={app} → FilterByAppResponse
interface FilterByAppResponse {
  bid_types: string[]
  countries: string[]
}

// 时间轴数据
GET /getAllDate?appname={app}&country={country} → string[]

// ROI数据
GET /getAllData?appname={app}&country={country} → RoiData[]
interface RoiData {
  roi_current: string
  roi_1d: string
  roi_3d: string
  roi_7d: string
  roi_14d: string
  roi_30d: string
  roi_60d: string
  roi_90d: string
}
```

## 性能优化策略

### 1. 组件优化
- 使用`defineAsyncComponent`懒加载
- 合理使用`computed`缓存计算
- 防抖处理用户输入

### 2. 图表优化
- ECharts按需引入
- ResizeObserver监听容器变化
- 数据预处理减少渲染计算

### 3. 网络优化
- Axios请求拦截器
- 错误重试机制
- 请求超时配置

### 4. 构建优化
- Vite构建优化
- 代码分割和懒加载
- 资源压缩和缓存

## 用户体验设计

### 1. 响应式体验
- 流畅的断点切换
- 优雅的加载状态
- 错误状态处理

### 2. 交互设计
- 直观的数据筛选
- 平滑的动画过渡
- 清晰的视觉反馈

### 3. 可访问性
- 语义化HTML结构
- 键盘导航支持
- 颜色对比度优化

## 部署架构

### 1. 容器化部署
```yaml
# docker-compose配置
services:
  frontend:
    build: .
    ports:
      - "80:80"
    environment:
      - NODE_ENV=production
```

### 2. Nginx配置
- 静态资源缓存
- Gzip压缩
- 反向代理配置

### 3. 环境配置
- 开发环境: Vite Dev Server
- 测试环境: Docker + Nginx
- 生产环境: 优化构建 + CDN

## 安全考虑

### 1. 数据安全
- API请求验证
- XSS防护
- CSRF保护

### 2. 部署安全
- HTTPS强制
- 安全头配置
- 依赖项安全扫描

## 扩展性设计

### 1. 模块化架构
- 插件式组件注册
- 主题系统支持
- 国际化准备

### 2. 数据扩展
- 灵活的类型系统
- 可配置的图表类型
- 多数据源支持

### 3. 功能扩展
- 导出功能预留
- 用户偏好设置
- 数据缓存机制

## 监控与维护

### 1. 错误监控
- 全局错误捕获
- 性能监控指标
- 用户行为分析

### 2. 开发工具
- Vue DevTools支持
- TypeScript类型检查
- ESLint代码规范

### 3. 测试策略
- 单元测试框架准备
- 集成测试设计
- E2E测试规划

## 总结

该ROI趋势分析仪表板采用现代化的前端技术栈，通过合理的架构设计和组件化开发，实现了高性能、高可用的数据可视化应用。系统具备良好的扩展性和维护性，为后续功能迭代奠定了坚实基础。

核心优势：
- 🎯 **专业性**: 专注ROI数据分析场景
- 🚀 **性能**: 优化的渲染和数据处理
- 📱 **适配性**: 全设备响应式支持  
- 🔧 **可维护**: 清晰的架构和代码组织
- 🎨 **用户体验**: 直观的交互和视觉设计