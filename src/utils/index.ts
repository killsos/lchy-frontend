import type { RoiData, SeriesDataItem } from '@/types'
import { SERIES_NAMES } from '@/constants'

// 处理数据的函数
export const processSeriesData = (
  seriesData: SeriesDataItem[],
  yAxisDataRaw: RoiData[]
): void => {
  // 1. 首先清空所有 seriesData 对象的 data 数组
  seriesData.forEach((item) => {
    item.data = []
  })

  // 2. 遍历 yAxisDataRaw 数组
  yAxisDataRaw.forEach((rawItem) => {
    // 为每个 seriesData 项目添加对应的数据
    seriesData.forEach((seriesItem) => {
      let value: number

      switch (seriesItem.name) {
        case SERIES_NAMES.CURRENT:
          value = parseFloat(rawItem.roi_current)
          break
        case SERIES_NAMES.ONE_DAY:
          value = parseFloat(rawItem.roi_1d)
          break
        case SERIES_NAMES.THREE_DAY:
          value = parseFloat(rawItem.roi_3d)
          break
        case SERIES_NAMES.SEVEN_DAY:
          value = parseFloat(rawItem.roi_7d)
          break
        case SERIES_NAMES.FOURTEEN_DAY:
          value = parseFloat(rawItem.roi_14d)
          break
        case SERIES_NAMES.THIRTY_DAY:
          value = parseFloat(rawItem.roi_30d)
          break
        case SERIES_NAMES.SIXTY_DAY:
          value = parseFloat(rawItem.roi_60d)
          break
        case SERIES_NAMES.NINETY_DAY:
          value = parseFloat(rawItem.roi_90d)
          break
        default:
          // 对于其他类型（如预测值），不处理
          return
      }

      // 将转换后的数值添加到对应的 data 数组中
      seriesItem.data.push(value)
    })
  })
}

export const movingAverage = (data: (number | null)[], windowSize: number): (number | null)[] => {
  const result: (number | null)[] = []
  // 确保窗口大小不超过数据长度
  if (windowSize > data.length) {
    return data.slice() // 返回原数据副本
  }
  
  for (let i = 0; i <= data.length - windowSize; i++) {
    const window = data.slice(i, i + windowSize)
    // 过滤掉null值进行计算
    const validNumbers = window.filter((val): val is number => val !== null)
    if (validNumbers.length === 0) {
      result.push(null)
    } else {
      const avg = validNumbers.reduce((sum, val) => sum + val, 0) / validNumbers.length
      result.push(parseFloat(avg.toFixed(2)))
    }
  }
  return result
}
