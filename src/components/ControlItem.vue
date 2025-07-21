<template>
  <div
    class="control-item-container flex-1 min-w-[340px] flex flex-col justify-center"
  >
    <div class="flex items-center justify-center">
      <h2 class="text-lg font-medium text-gray-900 pt-3 pb-3">
        {{ titleText }}
      </h2>
    </div>
    <!-- 分割线 -->
    <div class="w-full h-px bg-gray-200 mb-6"></div>

    <div class="flex items-center justify-between mt-4">
      <!-- 显示移动平均值选项 -->
      <div class="flex flex-col items-start">
        <div class="flex items-center pt-4">
          <input
            type="radio"
            :id="`mobile-average-${uniqueId}`"
            :name="`display-mode-${uniqueId}`"
            :value="channelOptions[0]"
            v-model="selectedMode"
            @change="handleModeChange(channelOptions[0])"
            class="w-4 h-4 text-blue-600 border-gray-300"
          />
          <label
            :for="`mobile-average-${uniqueId}`"
            class="pl-2 text-sm font-medium text-gray-900 cursor-pointer whitespace-nowrap"
          >
            {{ channelOptions[0] || '选项1' }}
          </label>
        </div>
        <!-- 蓝色下划线 - 只在选中移动平均值时显示 -->
        <div
          v-if="selectedMode === channelOptions[0]"
          class="w-full h-0.5 bg-blue-500 ml-6"
          style="margin-top: 0.25em"
        ></div>
      </div>

      <!-- 显示原始数据选项 -->
      <div class="flex flex-col items-start">
        <div class="flex items-center pt-4">
          <input
            type="radio"
            :id="`original-data-${uniqueId}`"
            :name="`display-mode-${uniqueId}`"
            :value="channelOptions[1]"
            v-model="selectedMode"
            @change="handleModeChange(channelOptions[1])"
            class="w-4 h-4 text-blue-600 border-gray-300"
          />
          <label
            :for="`original-data-${uniqueId}`"
            class="pl-2 text-sm font-medium text-gray-900 cursor-pointer whitespace-nowrap"
          >
            {{ channelOptions[1] || '选项2' }}
          </label>
        </div>
        <!-- 蓝色下划线 - 只在选中原始数据时显示 -->
        <div
          v-if="selectedMode === channelOptions[1]"
          class="w-full h-0.5 bg-blue-500 ml-6"
          style="margin-top: 0.25em"
        ></div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'

// 定义 props
const props = defineProps<{
  title: string
  options?: string[]
  modelValue?: string
}>()

// 定义 emits
const emit = defineEmits(['update:modelValue', 'change'])

// 生成唯一 ID
const uniqueId = Math.random().toString(36).substring(2, 9)

// 响应式数据
const titleText = ref(props.title || '加载中...')
const selectedMode = ref(props.modelValue || '')

// 响应式选项数据
const channelOptions = ref(props.options || [])


// 处理模式变化
const handleModeChange = (mode: string) => {
  selectedMode.value = mode
  emit('update:modelValue', mode)
  emit('change', mode)
}

// 监听 title 变化
watch(
  () => props.title,
  (newVal) => {
    titleText.value = newVal || '加载中...'
  }
)

// 监听modelValue
watch(
  () => props.modelValue,
  (newVal) => {
    if (newVal !== undefined && newVal !== null) {
      selectedMode.value = newVal
    }
  },
  { immediate: true }
)

// 监听options
watch(
  () => props.options,
  (newOptions) => {
    if (newOptions && newOptions.length > 0) {
      channelOptions.value = newOptions
    }
  },
  { deep: true, immediate: true }
)
</script>

<style scoped>
.control-item-container {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  padding: 1.5rem;
}

/* 单选按钮优化 */
input[type="radio"] {
  accent-color: #3b82f6;
  transform: scale(1.1);
}

/* 标签文字优化 */
label {
  font-weight: 500;
  letter-spacing: 0.025em;
}

/* 分割线优化 */
.h-px {
  background: linear-gradient(90deg, transparent, #e2e8f0, transparent);
}

/* 下划线动画 */
.bg-blue-500 {
  animation: slideIn 0.2s ease-out;
}

@keyframes slideIn {
  from {
    width: 0;
    opacity: 0;
  }
  to {
    width: 100%;
    opacity: 1;
  }
}
</style>
