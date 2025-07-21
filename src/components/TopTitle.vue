<script setup lang="ts">
import useFiltersStore from '@/stores/filters'
import { storeToRefs } from 'pinia'

const filtersStore = useFiltersStore()
const { currentAppName } = storeToRefs(filtersStore)
</script>

<template>
  <div class="bg-custom p-3 relative">
    <h1 class="text-4xl font-black text-center text-black pb-2">
      {{ currentAppName || '加载中...' }} - 多时间维度ROI趋势
    </h1>
    <h2 class="text-center text-lg text-gray-500">
      (7日移动平均)
    </h2>
    <h6 class="text-center text-sm pb-2 text-gray-500">
      数据范围: 最近90天
    </h6>
  </div>
</template>

<style scoped>
.bg-custom {
  background: #F5F5F7;
}

/* 主标题样式 */
h1 {
  font-weight: 900;
  color: #111827;
}

h2, h6 {
  color: #6b7280;
}
</style>
