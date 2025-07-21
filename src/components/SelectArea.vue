<template>
  <div class="flex flex-col gap-3 flex-1 min-w-0 test">
    <div class="text-base font-black text-black mb-1">{{ titleText }}</div>
    <el-select
      v-model="selectedChannel"
      placeholder="请选择安装渠道"
      size="large"
      class="w-full"
      :disabled="isDisabled"
      :class="{ 'select-disabled': isDisabled }"
      @change="handleChannelChange"
    >
      <el-option
        v-for="item in channelOptions"
        :key="item.value"
        :label="item.label"
        :value="item.value"
      />
    </el-select>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue'

// 定义类型
interface ChannelOption {
  label: string
  value: string
}

// 定义 props
const props = defineProps<{
  title?: string
  modelValue?: string
  options?: ChannelOption[]
}>()

// 设置默认值
const defaultOptions: ChannelOption[] = [{ label: 'Apple', value: 'apple' }]

// 定义 emits
const emit = defineEmits(['update:modelValue', 'change'])

// 响应式数据
const titleText = ref(props.title || '加载中...')
const selectedChannel = ref(props.modelValue || '请选择')
const channelOptions = ref(props.options || defaultOptions)

// 计算是否禁用选择器
const isDisabled = computed(() => channelOptions.value.length <= 1)

// 处理选择变化
const handleChannelChange = (value: string) => {
  emit('update:modelValue', value)
  emit('change', value)
}

// 监听外部值变化
watch(
  () => props.modelValue,
  (newVal) => {
    if (newVal !== undefined) {
      selectedChannel.value = newVal
    }
  }
)

// 监听 title 变化
watch(
  () => props.title,
  (newVal) => {
    titleText.value = newVal || '加载中...'
  }
)

// 监听options
watch(
  () => props.options,
  (newOptions) => {
    if (newOptions) {
      channelOptions.value = newOptions
    }
  },
  { deep: true }
)
</script>

<style scoped>
/* 基础样式 */
:deep(.el-input__wrapper) {
  border-radius: 6px;
  border: 1px solid #d1d5db;
  background: #ffffff;
  padding: 12px 16px;
  min-height: 44px;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

:deep(.el-input__wrapper:hover) {
  border-color: #9ca3af;
}

:deep(.el-input__wrapper.is-focus) {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

:deep(.el-input__inner) {
  font-size: 15px;
  font-weight: 500;
  color: #1f2937;
  background-color: transparent;
}

:deep(.el-input__inner::placeholder) {
  color: #6b7280;
  font-weight: 400;
}

:deep(.el-select__caret) {
  color: #6b7280;
  font-size: 16px;
}

/* 下拉菜单样式 */
:deep(.el-select-dropdown) {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  box-shadow: 
    0 20px 25px -5px rgba(0, 0, 0, 0.1), 
    0 10px 10px -5px rgba(0, 0, 0, 0.04);
  backdrop-filter: blur(8px);
}

:deep(.el-select-dropdown__item) {
  padding: 14px 18px;
  font-size: 15px;
  font-weight: 500;
  transition: all 0.2s ease;
  border-radius: 8px;
  margin: 4px 8px;
}

:deep(.el-select-dropdown__item:hover) {
  background: linear-gradient(145deg, #f8fafc 0%, #e2e8f0 100%);
  transform: translateX(2px);
}

:deep(.el-select-dropdown__item.selected) {
  background: linear-gradient(145deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  box-shadow: 
    0 4px 6px -1px rgba(59, 130, 246, 0.4),
    inset 0 1px 0 0 rgba(255, 255, 255, 0.2);
}

/* 禁用状态样式 */
.select-disabled :deep(.el-input__wrapper) {
  background: #f1f5f9 !important;
  border-color: #e2e8f0 !important;
  cursor: not-allowed !important;
  transform: none !important;
  box-shadow: none !important;
}

.select-disabled :deep(.el-input__inner) {
  color: #9ca3af !important;
  cursor: not-allowed !important;
}

.select-disabled :deep(.el-select__caret) {
  color: #9ca3af !important;
  cursor: not-allowed !important;
}

/* 标题文字优化 */
.text-base {
  font-weight: 600;
  letter-spacing: 0.025em;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}
</style>
