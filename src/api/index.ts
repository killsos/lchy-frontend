import request from '@/api/request'
import { filteByAppNameURL } from './httpURL'

interface FiltersByAppnameResponse {
  bid_types: string[]
  countries: string[]
}

export const getFilterByAppName = (
  appname: string
): Promise<FiltersByAppnameResponse> => {
  return request.get(filteByAppNameURL, {
    params: { appname },
  })
}
