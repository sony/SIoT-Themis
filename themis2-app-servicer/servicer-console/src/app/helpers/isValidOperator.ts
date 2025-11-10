import { operators } from '@/app/constants/operators'

export const isValidOperator = (arg: string): boolean => {
  return operators.some((operator) => operator.value === arg)
}
