// Application Constants

// Default Values
export const DEFAULT_APP = 'App-1'
export const DEFAULT_COUNTRY = '美国'

// Chart Configuration
export const CHART_COLORS = [
  '#dc2626', // 红色系
  '#059669', // 绿色系
  '#0d9488', // 青色系
  '#0891b2', // 天蓝色系
  '#2563eb', // 蓝色系
  '#7c3aed', // 紫色系
  '#d97706', // 橙色系
  '#e11d48', // 玫红色系
  '#16a34a', // 亮绿色系
  '#0369a1', // 深蓝色系
  '#9333ea', // 亮紫色系
  '#ca8a04', // 金黄色系
  '#be123c', // 深红色系
  '#047857', // 深绿色系
  '#1e40af', // 蓝紫色系
] as const

// Y-axis Tick Values
export const Y_AXIS_TICKS = [7, 10, 20, 30, 50, 70, 100, 200, 300, 500] as const
export const LOG_Y_AXIS_TICKS = [1, 10, 100, 1000] as const

// Display Options
export const DISPLAY_MODES = {
  MOVING_AVERAGE: '显示移动平均值',
  RAW_DATA: '显示原始数据',
} as const

export const Y_AXIS_TYPES = {
  LINEAR: '线性刻度',
  LOGARITHMIC: '对数刻度',
} as const

// Series Names
export const SERIES_NAMES = {
  CURRENT: '当日(7日均值)',
  ONE_DAY: '1日(7日均值)',
  THREE_DAY: '3日(7日均值)',
  SEVEN_DAY: '7日(7日均值)',
  FOURTEEN_DAY: '14日(7日均值)',
  THIRTY_DAY: '30日(7日均值)',
  SIXTY_DAY: '60日(7日均值)',
  NINETY_DAY: '90日(7日均值)',
  PREDICTION: '预测值',
} as const

// Moving Average Window Size
export const MOVING_AVERAGE_WINDOW = 7

// Responsive Breakpoints (matching Tailwind CSS)
export const BREAKPOINTS = {
  SM: 640,
  MD: 768,
  LG: 1024,
  XL: 1280,
  '2XL': 1536,
} as const

// API Configuration
export const API_TIMEOUT = 10000
export const REQUEST_RETRY_COUNT = 3

// Chart Dimensions
export const CHART_MIN_HEIGHT = {
  MOBILE: 300,
  DESKTOP: 500,
} as const