<script setup lang="ts">
import SelectArea from '@/components/SelectArea.vue'
import TopTitle from '@/components/TopTitle.vue'
import ControlItem from '@/components/ControlItem.vue'
import ROIChart from '@/components/ROIChart.vue'

import useFiltersStore from '@/stores/filters'
import useDisplayStore from '@/stores/display'
import useChartStore from '@/stores/chart'
import { storeToRefs } from 'pinia'
import { onMounted } from 'vue'

const filtersStore = useFiltersStore()
const displayStore = useDisplayStore()
const chartStore = useChartStore()

const {
  currentAppName,
  currentbidType,
  currentCountry,
  appNames,
  bidTypes,
  countries,
} = storeToRefs(filtersStore)

// 直接从 store 获取数据
const showModelData = displayStore.showModelData
const yAxisTicks = displayStore.yAxisTicks
const { currentShowModelData, currentYAxisTick } = storeToRefs(displayStore)

/**
 * 处理出价类型选择变化
 * @param value 选中的出价类型值
 */
const handleBidTypeChange = (value: string) => {
  filtersStore.currentbidType = value
}

/**
 * 处理国家地区选择变化
 * @param value 选中的国家地区值
 */
const handleCountryChange = (value: string) => {
  filtersStore.currentCountry = value
  chartStore.changeAppNameOrCountry(currentAppName.value, value)
}

/**
 * 处理应用名称选择变化
 * @param value 选中的应用名称
 */
const handleAppNameChange = (value: string) => {
  filtersStore.currentAppName = value
  filtersStore.filterByAppName(value)
  chartStore.changeAppNameOrCountry(value, currentCountry.value)
}

/**
 * 处理数据显示模式变化
 * @param value 选中的显示模式
 */
const handleShowModelDataChange = (value: string) => {
  displayStore.setShowModelData(value)
}

/**
 * 处理Y轴刻度选择变化
 * @param value 选中的Y轴刻度值
 */
const handleYAxisTickChange = (value: string) => {
  displayStore.setYAxisTick(value)
}

// 组件挂载时加载数据
onMounted(async () => {
  await filtersStore.loadFilters()
  await chartStore.initData('App-1', '美国')
})
</script>

<template>
  <div class="homeArea">
    <!-- 桌面端：上下布局 -->
    <div class="hidden xl:block">
      <div class="bgColor p-6 min-h-screen transition-colors duration-300">
        <TopTitle></TopTitle>
        <div
          class="test middle-area bg-white border border-gray-200 rounded-lg p-6 transition-all duration-300"
          style="
            box-shadow:
              0 10px 20px rgba(141, 142, 142, 0.6),
              0 20px 40px rgba(0, 0, 0, 0.3);
          "
        >
          <!-- 选择区 -->
          <div class="grid grid-cols-4 gap-4">
            <SelectArea
              :modelValue="'Apple'"
              :options="[{ label: 'Apple', value: 'Apple' }]"
              title="用户安装渠道"
            ></SelectArea>
            <SelectArea
              :modelValue="currentbidType"
              :options="bidTypes"
              title="出价类型"
              @update:modelValue="handleBidTypeChange"
              @change="handleBidTypeChange"
            ></SelectArea>
            <SelectArea
              :modelValue="currentCountry"
              :options="countries"
              title="国家地区"
              @update:modelValue="handleCountryChange"
              @change="handleCountryChange"
            ></SelectArea>
            <SelectArea
              :modelValue="currentAppName"
              :options="appNames"
              title="APP"
              @update:modelValue="handleAppNameChange"
              @change="handleAppNameChange"
            ></SelectArea>
          </div>

          <!-- 控制区 -->
          <div class="flex gap-6 pt-6">
            <div class="flex-1 min-w-[200px]">
              <ControlItem
                title="数据显示模式"
                :options="showModelData"
                :modelValue="currentShowModelData"
                @update:modelValue="handleShowModelDataChange"
              ></ControlItem>
            </div>
            <div class="flex-1 min-w-[160px]">
              <ControlItem
                title="Y轴刻度"
                :modelValue="currentYAxisTick"
                :options="yAxisTicks"
                @update:modelValue="handleYAxisTickChange"
              ></ControlItem>
            </div>
          </div>
        </div>

        <div
          class="chartArea bg-white border border-gray-200 rounded-lg p-6 h-[600px] transition-all duration-300"
          style="
            margin-top: 10px;
            box-shadow:
              0 10px 20px rgba(141, 142, 142, 0.6),
              0 20px 40px rgba(0, 0, 0, 0.3);
          "
        >
          <ROIChart></ROIChart>
        </div>
      </div>
    </div>

    <!-- 平板端：上下布局 -->
    <div class="hidden md:block xl:hidden">
      <div class="bgColor p-5 min-h-screen transition-colors duration-300">
        <TopTitle></TopTitle>
        <div
          class="test middle-area bg-white border border-gray-200 rounded-lg p-5 transition-all duration-300"
          style="
            box-shadow:
              0 10px 20px rgba(141, 142, 142, 0.6),
              0 20px 40px rgba(0, 0, 0, 0.3);
          "
        >
          <!-- 选择区 - 2x2网格 -->
          <div class="grid grid-cols-2 gap-3">
            <SelectArea
              :modelValue="'Apple'"
              :options="[{ label: 'Apple', value: 'Apple' }]"
              title="用户安装渠道"
            ></SelectArea>
            <SelectArea
              :modelValue="currentbidType"
              :options="bidTypes"
              title="出价类型"
              @update:modelValue="handleBidTypeChange"
              @change="handleBidTypeChange"
            ></SelectArea>
            <SelectArea
              :modelValue="currentCountry"
              :options="countries"
              title="国家地区"
              @update:modelValue="handleCountryChange"
              @change="handleCountryChange"
            ></SelectArea>
            <SelectArea
              :modelValue="currentAppName"
              :options="appNames"
              title="APP"
              @update:modelValue="handleAppNameChange"
              @change="handleAppNameChange"
            ></SelectArea>
          </div>

          <!-- 控制区 -->
          <div class="flex gap-4 pt-4">
            <div class="flex-1 min-w-[180px]">
              <ControlItem
                title="数据显示模式"
                :options="showModelData"
                :modelValue="currentShowModelData"
                @update:modelValue="handleShowModelDataChange"
              ></ControlItem>
            </div>
            <div class="flex-1 min-w-[140px]">
              <ControlItem
                title="Y轴刻度"
                :modelValue="currentYAxisTick"
                :options="yAxisTicks"
                @update:modelValue="handleYAxisTickChange"
              ></ControlItem>
            </div>
          </div>
        </div>

        <div
          class="chartArea bg-white border border-gray-200 rounded-lg p-5 transition-all duration-300"
          style="
            margin-top: 10px;
            box-shadow:
              0 10px 20px rgba(141, 142, 142, 0.6),
              0 20px 40px rgba(0, 0, 0, 0.3);
          "
        >
          <ROIChart></ROIChart>
        </div>
      </div>
    </div>

    <!-- 移动端：单列垂直布局 -->
    <div class="block md:hidden">
      <div class="bgColor p-4 min-h-screen transition-colors duration-300">
        <TopTitle></TopTitle>
        <div
          class="test middle-area bg-white border border-gray-200 rounded-lg p-4 transition-all duration-300"
          style="
            box-shadow:
              0 10px 20px rgba(141, 142, 142, 0.6),
              0 20px 40px rgba(0, 0, 0, 0.3);
          "
        >
          <!-- 选择区 - 单列布局 -->
          <div class="space-y-3">
            <SelectArea
              :modelValue="'Apple'"
              :options="[{ label: 'Apple', value: 'Apple' }]"
              title="用户安装渠道"
            ></SelectArea>
            <SelectArea
              :modelValue="currentbidType"
              :options="bidTypes"
              title="出价类型"
              @update:modelValue="handleBidTypeChange"
              @change="handleBidTypeChange"
            ></SelectArea>
            <SelectArea
              :modelValue="currentCountry"
              :options="countries"
              title="国家地区"
              @update:modelValue="handleCountryChange"
              @change="handleCountryChange"
            ></SelectArea>
            <SelectArea
              :modelValue="currentAppName"
              :options="appNames"
              title="APP"
              @update:modelValue="handleAppNameChange"
              @change="handleAppNameChange"
            ></SelectArea>
          </div>

          <!-- 控制区 -->
          <div class="flex flex-col gap-3 pt-4">
            <ControlItem
              title="数据显示模式"
              :options="showModelData"
              :modelValue="currentShowModelData"
              @update:modelValue="handleShowModelDataChange"
            ></ControlItem>
            <ControlItem
              title="Y轴刻度"
              :modelValue="currentYAxisTick"
              :options="yAxisTicks"
              @update:modelValue="handleYAxisTickChange"
            ></ControlItem>
          </div>
        </div>

        <div
          class="chartArea bg-white border border-gray-200 rounded-lg p-4 transition-all duration-300"
          style="
            margin-top: 10px;
            box-shadow:
              0 10px 20px rgba(141, 142, 142, 0.6),
              0 20px 40px rgba(0, 0, 0, 0.3);
          "
        >
          <ROIChart></ROIChart>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.bgColor {
  background: #f3f4f6;
  transition: background 0.2s ease;
}

.homeArea {
  min-height: 100vh;
}

/* 滚动条样式 */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>
