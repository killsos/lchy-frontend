// Global type definitions

// API Response Types
export interface ApiResponse<T = unknown> {
  code: number
  data: T
  message: string
}

// ROI Data Interface
export interface RoiData {
  roi_current: string
  roi_1d: string
  roi_3d: string
  roi_7d: string
  roi_14d: string
  roi_30d: string
  roi_60d: string
  roi_90d: string
}

// Chart Series Data
export interface SeriesDataItem {
  name: string
  data: (number | null)[]
  color: string
  dashed?: boolean
}

// Filter Options
export interface FilterOption {
  label: string
  value: string
}

// Theme Colors
export interface ThemeColors {
  background: string
  text: string
  textSecondary: string
  border: string
  surface: string
  grid: string
  axis: string
}

// Chart Configuration
export interface ChartConfig {
  yAxisType: '线性刻度' | '对数刻度'
  showModel: '显示移动平均值' | '显示原始数据'
}

// Common Types
export type LoadingState = 'idle' | 'loading' | 'success' | 'error'

// HTTP Request Config
export interface RequestConfig {
  timeout?: number
  headers?: Record<string, string>
  params?: Record<string, unknown>
}