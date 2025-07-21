import axios from 'axios'
import type { AxiosInstance, AxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'
import { API_TIMEOUT } from '@/constants'

class HttpRequest {
  private instance: AxiosInstance

  constructor() {
    this.instance = axios.create({
      baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
      timeout: API_TIMEOUT,
      headers: {
        'Content-Type': 'application/json',
      },
    })

    this.interceptors()
  }

  private interceptors() {
    // 请求拦截
    this.instance.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('token')
        if (token) {
          config.headers.Authorization = `Bearer ${token}`
        }
        return config
      },
      (error) => Promise.reject(error)
    )

    // 响应拦截
    this.instance.interceptors.response.use(
      (response) => {
        const { code, data, message } = response.data
        if (code === 200) {
          return data
        } else {
          ElMessage.error(message || '请求失败')
          return Promise.reject(new Error(message))
        }
      },
      (error) => {
        ElMessage.error(error.message || '网络错误')
        return Promise.reject(error)
      }
    )
  }

  public request<T = unknown>(config: AxiosRequestConfig): Promise<T> {
    return this.instance.request(config)
  }

  public get<T = unknown>(
    url: string,
    config?: AxiosRequestConfig
  ): Promise<T> {
    return this.instance.get(url, config)
  }

  public post<T = unknown>(
    url: string,
    data?: unknown,
    config?: AxiosRequestConfig
  ): Promise<T> {
    return this.instance.post(url, data, config)
  }

  public put<T = unknown>(
    url: string,
    data?: unknown,
    config?: AxiosRequestConfig
  ): Promise<T> {
    return this.instance.put(url, data, config)
  }

  public delete<T = unknown>(
    url: string,
    config?: AxiosRequestConfig
  ): Promise<T> {
    return this.instance.delete(url, config)
  }
}

export default new HttpRequest()
