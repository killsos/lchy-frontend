<script setup lang="ts">
import { ref, watch, onMounted, nextTick, onUnmounted, computed } from 'vue'
import { storeToRefs } from 'pinia'
import * as echarts from 'echarts'
import useDisplayStore from '@/stores/display'
import useChartStore from '@/stores/chart'
import { processSeriesData, movingAverage } from '@/utils/index'
import type { SeriesDataItem, ThemeColors } from '@/types'
import { 
  CHART_COLORS, 
  Y_AXIS_TICKS, 
  LOG_Y_AXIS_TICKS, 
  SERIES_NAMES,
  MOVING_AVERAGE_WINDOW,
  BREAKPOINTS,
  CHART_MIN_HEIGHT
} from '@/constants'

const displayStore = useDisplayStore()
const chartStore = useChartStore()

const { currentShowModelData, currentYAxisTick } = storeToRefs(displayStore)
const { xAxisDataRaw, yAxisDataRaw } = storeToRefs(chartStore)
const chartRef = ref(null)
const xAxisData = xAxisDataRaw
// const xAxisData = [
//   '4月19日',
//   '4月24日',
//   '4月29日',
//   '5月3日',
//   '5月7日',
//   '5月15日',
//   '5月20日',
//   '5月25日',
//   '5月30日',
//   '6月5日',
//   '6月11日',
//   '6月20日',
//   '6月30日',
//   '7月4日',
//   '7月8日',
//   '7月12日',
// ]

// 获取系列数据的动态颜色配置
const getSeriesData = (): SeriesDataItem[] => {

  return [
    {
      name: SERIES_NAMES.CURRENT,
      data: [10, 20, 18, 16, 12, 10, 9, 8, 7.5, 8, 7.8, 7.5, 7.2, 7, 6.5, 6.8],
      color: CHART_COLORS[0],
    },
    {
      name: SERIES_NAMES.ONE_DAY,
      data: [
        20, 28, 30, 27, 24, 22, 21, 19, 18, 18.5, 18, 17, 16.5, 16, 15.5, 15,
      ],
      color: CHART_COLORS[1],
    },
    {
      name: SERIES_NAMES.THREE_DAY,
      data: [40, 45, 50, 48, 46, 44, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33],
      color: CHART_COLORS[2],
    },
    {
      name: SERIES_NAMES.SEVEN_DAY,
      data: [
        100, 105, 110, 108, 105, 103, 101, 99, 97, 95, 92, 90, 89, 88, 87, 86,
      ],
      color: CHART_COLORS[3],
    },
    {
      name: SERIES_NAMES.FOURTEEN_DAY,
      data: [80, 85, 83, 81, 79, 77, 75, 74, 73, 72, 71, 70, 69, 68, 67, 66],
      color: CHART_COLORS[4],
    },
    {
      name: SERIES_NAMES.THIRTY_DAY,
      data: [60, 65, 63, 61, 59, 58, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47],
      color: CHART_COLORS[5],
    },
    {
      name: SERIES_NAMES.SIXTY_DAY,
      data: [6, 165, 3, 161, 59, 58, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47],
      color: CHART_COLORS[6],
    },
    {
      name: SERIES_NAMES.NINETY_DAY,
      data: [
        160, 165, 163, 161, 159, 158, 156, 155, 154, 153, 152, 151, 150, 49, 48,
        147,
      ],
      color: CHART_COLORS[7],
    },
    {
      name: SERIES_NAMES.PREDICTION,
      data: [
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        300,
        320,
        310,
        290,
      ],
      color: CHART_COLORS[6],
      dashed: true,
    },
  ]
}

const seriesData = ref<SeriesDataItem[]>(getSeriesData())

const changeShowModel = (showModel: string) => {
  // 显示移动平均值
  if (showModel === '显示移动平均值') {
    seriesData.value.forEach((item) => {
      switch (item.name) {
        case SERIES_NAMES.THREE_DAY:
          item.data = movingAverage(item.data, MOVING_AVERAGE_WINDOW)
          break
        case SERIES_NAMES.SEVEN_DAY:
          item.data = movingAverage(item.data, MOVING_AVERAGE_WINDOW)
          break
        case SERIES_NAMES.FOURTEEN_DAY:
          item.data = movingAverage(item.data, MOVING_AVERAGE_WINDOW)
          break
        case SERIES_NAMES.THIRTY_DAY:
          item.data = movingAverage(item.data, MOVING_AVERAGE_WINDOW)
          break
        case SERIES_NAMES.SIXTY_DAY:
          item.data = movingAverage(item.data, MOVING_AVERAGE_WINDOW)
          break
        case SERIES_NAMES.NINETY_DAY:
          item.data = movingAverage(item.data, MOVING_AVERAGE_WINDOW)
          break
      }
    })
  } else {
    // 显示原始数据
    processSeriesData(seriesData.value, yAxisDataRaw.value)
  }
  chart?.setOption(getOption())
}

// 监听数据变化，更新图表数据
watch(
  yAxisDataRaw,
  (newData) => {
    if (newData && newData.length > 0) {
      // processSeriesData(seriesData.value, newData)
      changeShowModel(currentShowModelData.value)
      if (chart) {
        chart.setOption(getOption())
      }
    }
  },
  { immediate: true }
)


// 响应式屏幕检测
const screenSize = ref(window.innerWidth)
const isSmallScreen = computed(() => screenSize.value < BREAKPOINTS.MD)

// 更新屏幕尺寸
const updateScreenSize = () => {
  screenSize.value = window.innerWidth
}

let chart: echarts.ECharts | null = null
let resizeObserver: ResizeObserver | null = null

// 获取颜色配置
const getThemeColors = (): ThemeColors => {
  return {
    background: '#ffffff',
    text: '#1f2937',
    textSecondary: '#6b7280',
    border: '#e5e7eb',
    surface: '#ffffff',
    grid: '#e5e7eb',
    axis: '#9ca3af',
  }
}

// 获取响应式配置
const getOption = () => {
  const colors = getThemeColors()

  return {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      valueFormatter: (v: number | null) =>
        v != null ? `${v.toFixed(1)}%` : '-',
      textStyle: {
        fontSize: isSmallScreen.value ? 10 : 12,
        color: colors.text,
      },
      backgroundColor: colors.surface,
      borderColor: colors.border,
      borderWidth: 1,
    },
    legend: {
      bottom: isSmallScreen.value ? 15 : 30,
      textStyle: {
        fontSize: isSmallScreen.value ? 10 : 12,
        color: colors.text,
      },
    },
    grid: {
      left: isSmallScreen.value ? '10%' : '8%',
      right: isSmallScreen.value ? '10%' : '8%',
      bottom: isSmallScreen.value ? '25%' : '20%',
      top: isSmallScreen.value ? '20%' : '15%',
      containLabel: true,
    },
    xAxis: {
      type: 'category',
      data: xAxisData.value,
      boundaryGap: false,
      splitLine: {
        show: true,
        lineStyle: {
          color: colors.grid,
          width: 1,
          type: 'dashed',
        },
      },
      axisLabel: {
        fontSize: isSmallScreen.value ? 10 : 12,
        color: colors.textSecondary,
      },
      axisLine: {
        lineStyle: {
          color: colors.border,
        },
      },
      axisTick: {
        lineStyle: {
          color: colors.border,
        },
      },
    },
    yAxis: {
      type: currentYAxisTick.value == '线性刻度' ? 'value' : 'log',
      splitLine: {
        show: true,
        lineStyle: {
          color: colors.grid,
          width: 1,
          type: 'dashed',
        },
      },
      min: currentYAxisTick.value == '线性刻度' ? 0 : 1,
      max: currentYAxisTick.value == '线性刻度' ? 500 : 1000,
      splitNumber:
        currentYAxisTick.value == '线性刻度'
          ? Y_AXIS_TICKS.length - 1
          : LOG_Y_AXIS_TICKS.length - 1,
      axisTick: {
        show: true,
        alignWithLabel: true,
        lineStyle: {
          color: colors.border,
        },
      },
      axisLabel: {
        formatter: (value: number) => {
          if (currentYAxisTick.value == '线性刻度') {
            return (Y_AXIS_TICKS as readonly number[]).includes(value) ? value.toString() : ''
          }

          if (currentYAxisTick.value == '对数刻度') {
            return (LOG_Y_AXIS_TICKS as readonly number[]).includes(value) ? value.toString() : ''
          }
        },
        fontWeight: 'bold',
        fontSize: isSmallScreen.value ? 10 : 12,
        color: colors.textSecondary,
      },
      axisLine: {
        show: true,
        lineStyle: {
          color: colors.border,
        },
      },
      axisPointer: { show: true },
      interval: null,
    },
    series: seriesData.value.map((s, idx) => ({
      name: s.name,
      type: 'line',
      data: s.data,
      smooth: true,
      showSymbol: false,
      lineStyle: {
        color: s.color,
        width: 2,
        type: s.dashed ? 'dashed' : 'solid',
      },
      ...(idx === 0 && {
        markLine: {
          silent: true,
          symbol: 'none',
          label: {
            formatter: '100%回本线',
            position: 'insideEndTop',
            fontWeight: 'bold',
            color: '#991b1b',
            backgroundColor: '#ffffff',
            padding: [3, 6],
            borderRadius: 4,
            fontSize: isSmallScreen.value ? 9 : 11,
            offset: [-10, 0],
            borderColor: '#ef4444',
            borderWidth: 1,
          },
          lineStyle: {
            color: '#ef4444',
            width: 2,
            type: 'dashed',
          },
          data: [{ yAxis: 100 }],
        },
      }),
    })),
    dataZoom: [
      {
        type: 'slider',
        height: isSmallScreen.value ? 15 : 20,
        bottom: isSmallScreen.value ? 50 : 70,
        textStyle: {
          fontSize: isSmallScreen.value ? 10 : 12,
          color: colors.textSecondary,
        },
        backgroundColor: colors.surface,
        borderColor: colors.border,
        fillerColor: 'rgba(59, 130, 246, 0.1)',
        handleStyle: {
          color: '#2563eb',
          borderColor: colors.border,
        },
        dataBackground: {
          lineStyle: {
            color: colors.border,
          },
          areaStyle: {
            color: 'rgba(156, 163, 175, 0.2)',
          },
        },
      },
      { type: 'inside' },
    ],
    toolbox: {
      feature: {
        dataZoom: {
          yAxisIndex: false,
          title: {
            zoom: '区域缩放',
            back: '缩放还原',
          },
          icon: {
            zoom: 'path://M10,2 C14.418,2 18,5.582 18,10 C18,14.418 14.418,18 10,18 C5.582,18 2,14.418 2,10 C2,5.582 5.582,2 10,2 Z M15,15 L20,20 M10,6 L10,14 M6,10 L14,10',
            back: 'path://M3,3 L21,21 M21,3 L3,21',
          },
        },
        restore: {
          title: '还原',
          icon: 'path://M4,12 C4,7.6 7.6,4 12,4 C16.4,4 20,7.6 20,12 C20,16.4 16.4,20 12,20 C7.6,20 4,16.4 4,12 Z M8,12 L12,8 L16,12 L12,16 Z',
        },
      },
      top: isSmallScreen.value ? 5 : 10,
      right: isSmallScreen.value ? 10 : 20,
      iconStyle: {
        borderColor: '#3b82f6',
        color: 'transparent',
      },
      emphasis: {
        iconStyle: {
          borderColor: '#60a5fa',
          color: '#f0f9ff',
        },
      },
    },
  }
}

// Y轴刻度变化监听
watch(currentYAxisTick, () => {
  if (chart) {
    chart.setOption(getOption())
  }
})

// 屏幕尺寸变化监听
watch(screenSize, () => {
  if (chart) {
    nextTick(() => {
      chart?.setOption(getOption())
      chart?.resize()
    })
  }
})

// 数据显示模式监听
watch(currentShowModelData, (newValue) => {
  if (newValue && newValue != '') {
    changeShowModel(newValue)
  }
})

onMounted(() => {
  // 初始化图表
  if (chartRef.value) {
    chart = echarts.init(chartRef.value)
    chart.setOption(getOption())

    // 监听窗口大小变化
    window.addEventListener('resize', updateScreenSize)
    window.addEventListener('resize', () => {
      if (chart) {
        chart.resize()
      }
    })

    // 使用ResizeObserver监听容器大小变化
    resizeObserver = new ResizeObserver(() => {
      if (chart) {
        nextTick(() => {
          chart?.resize()
        })
      }
    })
    resizeObserver.observe(chartRef.value)
  }
})

onUnmounted(() => {
  // 清理事件监听器
  window.removeEventListener('resize', updateScreenSize)
  if (resizeObserver) {
    resizeObserver.disconnect()
  }
  if (chart) {
    chart.dispose()
  }
})
</script>

<template>
  <div class="chart-container h-full w-full">
    <div class="chart-wrapper h-full w-full flex flex-col">
      <div
        ref="chartRef"
        :class="`flex-1 w-full bg-white rounded-lg min-h-[${CHART_MIN_HEIGHT.MOBILE}px] xl:min-h-[${CHART_MIN_HEIGHT.DESKTOP}px] transition-colors duration-200`"
      ></div>
    </div>
  </div>
</template>

<style scoped></style>
