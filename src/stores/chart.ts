import { ref } from 'vue'
import request from '@/api/request'
import { defineStore } from 'pinia'
import { getAllDateURL, getAllDataURL } from '@/api/httpURL'
import type { RoiData } from '@/types'

async function getAllDate(appName: string, country: string): Promise<string[]> {
  const result = await request.get<string[]>(getAllDateURL, {
    params: {
      appname: appName,
      country,
    },
  })
  return result
}

async function getAllData(
  appName: string,
  country: string
): Promise<RoiData[]> {
  const result = await request.get<RoiData[]>(getAllDataURL, {
    params: {
      appname: appName,
      country,
    },
  })
  return result
}

export default defineStore('chart', () => {
  const xAxisDataRaw = ref<string[]>([])
  const yAxisDataRaw = ref<RoiData[]>([])
  const initData = async (appName: string, country: string) => {
    xAxisDataRaw.value = await getAllDate(appName, country)
    yAxisDataRaw.value = await getAllData(appName, country)
  }

  const changeAppNameOrCountry = async (appName: string, country: string) => {
    xAxisDataRaw.value = await getAllDate(appName, country)
    yAxisDataRaw.value = await getAllData(appName, country)
  }

  return {
    xAxisDataRaw,
    yAxisDataRaw,
    initData,
    changeAppNameOrCountry,
  }
})
