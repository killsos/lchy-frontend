import { ref } from 'vue'
import { defineStore } from 'pinia'
import request from '@/api/request'
import { getFiltersURL } from '@/api/httpURL'
import { getFilterByAppName } from '@/api/index'

// 定义返回类型接口
interface FiltersResponse {
  app_names: string[]
  bid_types: string[]
  countries: string[]
}

/**
 * 获取过滤器数据
 * @returns Promise<FiltersResponse> 包含app名称、出价类型、国家地区的过滤器数据
 */
async function getFilters(): Promise<FiltersResponse> {
  const result = await request.get(getFiltersURL)
  return result as FiltersResponse
}

/**
 * 数据格式转换函数
 * @param arr 字符串数组
 * @returns 转换为 {label, value} 格式的对象数组
 */
function dataFormatConversion(arr: string[]) {
  return arr.map((item: string) => ({ label: item, value: item }))
}
export default defineStore('filters', () => {
  const appNames = ref<{ label: string; value: string }[]>([])
  const bidTypes = ref<{ label: string; value: string }[]>([])
  const countries = ref<{ label: string; value: string }[]>([])
  const installationChannel = ref<string[]>(['Apple'])

  const currentAppName = ref<string>('')
  const currentbidType = ref<string>('')
  const currentCountry = ref<string>('')
  const currentInstallationChannel = ref<string>('Apple')

  /**
   * 根据应用名称过滤数据
   * @param appname 应用名称
   */
  const filterByAppName = async (appname: string) => {
    try {
      const { bid_types, countries: countriesData } =
        await getFilterByAppName(appname)
      bidTypes.value = dataFormatConversion(bid_types || [])
      countries.value = dataFormatConversion(countriesData || [])
      if (countries.value.length > 0) {
        currentCountry.value = countries.value[0].value
      } else {
        currentCountry.value = ''
      }
    } catch (error) {
      console.error('Failed to load filtersByAppname:', error)
    }
  }

  /**
   * 异步加载过滤器数据并设置默认值
   */
  const loadFilters = async () => {
    try {
      const {
        app_names,
        bid_types,
        countries: countriesData,
      } = await getFilters()

      appNames.value = dataFormatConversion(app_names || [])
      bidTypes.value = dataFormatConversion(bid_types || [])
      countries.value = dataFormatConversion(countriesData || [])

      // 设置默认值
      if (app_names?.length > 0) {
        currentAppName.value = app_names[0]
      }
      if (bid_types?.length > 0) {
        currentbidType.value = bid_types[0]
      }
      if (countriesData?.length > 0) {
        currentCountry.value = countriesData[0]
      }
    } catch (error) {
      console.error('Failed to load filters:', error)
    }
  }

  return {
    appNames,
    bidTypes,
    countries,
    installationChannel,
    currentAppName,
    currentbidType,
    currentCountry,
    currentInstallationChannel,
    loadFilters,
    filterByAppName,
  }
})
