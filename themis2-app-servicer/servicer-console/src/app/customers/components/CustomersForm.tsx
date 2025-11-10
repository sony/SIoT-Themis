'use client'

import { Box, Button, Typography } from '@mui/material'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { useTranslations } from 'next-intl'
import { useState, useContext, useEffect, useActionState } from 'react'

import type { ServerActionResponse } from '@/types/actions'
import type { Customer, Type, Condition, Subscription } from 'schema/prisma/client/'

import { deleteCustomer } from '@/app/actions/customers'
import { ApiKey } from '@/app/components/form/ApiKey'
import { ConfirmableButton } from '@/app/components/form/ConfirmableButton'
import { CustomerName } from '@/app/components/form/CustomerName'
import { Types } from '@/app/components/form/Types'
import { isEmpty } from '@/app/helpers/isEmpty'
import { SnackbarContext } from '@/app/SnackbarProvider'

type ValidationError = { [key: string]: string | null }

type CustomerFormProps = {
  customer?: Customer & {
    types: (Type & {
      conditions: Condition[]
      subscriptions: Subscription[]
    })[]
  }
  submitAction: (_: ServerActionResponse<Customer>, formData: FormData) => Promise<ServerActionResponse<Customer>>
}

export function CustomerForm({ customer, submitAction }: CustomerFormProps) {
  const t = useTranslations()
  const router = useRouter()
  const pathname = usePathname()

  const { setAlert } = useContext(SnackbarContext)

  const [validationError, setValidationError] = useState<ValidationError>({})
  const [typesData, setTypesData] = useState<
    {
      type: { type: string; id: string }
      subscriptions: { id: number; endpoint: string }[]
      conditions: { id: number; key: string; operator: string; value: string }[]
    }[]
  >([])
  const [customerName, setCustomerName] = useState('')

  const initialState: ServerActionResponse<Customer> = {
    success: false,
    errors: {},
  }

  const [state, formAction] = useActionState(submitAction, initialState)

  useEffect(() => {
    if (!customer) return

    setCustomerName(customer.name)

    const typesWithDetails = customer.types.map(
      (type: Type & { subscriptions: Subscription[]; conditions: Condition[] }) => ({
        type: {
          id: String(type.id),
          type: type.type,
        },
        subscriptions:
          type.subscriptions?.map((subscription: Subscription, index: number) => ({
            id: subscription.id || index,
            endpoint: subscription.endpoint,
          })) || [],
        conditions: type.conditions?.length
          ? type.conditions.map((condition: Condition, index: number) => ({
              id: Number(condition.id) || index,
              key: condition.key,
              operator: condition.operator,
              value: condition.value,
            }))
          : [{ id: 0, key: '', operator: '', value: '' }],
      }),
    )

    setTypesData(typesWithDetails)
  }, [customer])

  useEffect(() => {
    if (state.success) {
      setAlert({
        severity: 'success',
        message: t('CustomerEdit.successSaved', { name: state.data.name }),
      })
      router.push(`/customers/${state.data.id}`)
    } else if (!state.success) {
      if (isEmpty(state.errors)) return
      const errorMessage = Object.values(state.errors).join('\n')
      setAlert({
        severity: 'error',
        message: errorMessage,
      })
      setValidationError((validationError) => ({ ...validationError, ...state.errors }))
    }
  }, [state, router, pathname, setAlert, t])

  const onDeleteDialogOk = async () => {
    const deleteResult = await deleteCustomer(customer!.id)
    if (!deleteResult.success) {
      if (isEmpty(deleteResult.errors)) return
      const errorMessage = Object.values(deleteResult.errors).join('\n')
      setAlert({
        severity: 'error',
        message: errorMessage,
      })
      return
    }
    setAlert({
      severity: 'success',
      message: t('CustomerEdit.successDeleted', { name: customer!.name }),
    })
    router.push('/customers/list')
  }

  const handleFormSubmit = async (formData: FormData) => {
    const formName = formData.get('name')?.toString() ?? ''
    setCustomerName(formName)
    const hasErrors = Object.values(validationError).some((error) => error !== null && error !== '')
    if (hasErrors) {
      return
    }
    typesData.forEach((typeData, rowCount: number) => {
      const typeId = typeData.type.id || `${rowCount}new`
      formData.append(`type-${typeId}`, JSON.stringify(typeData.type))
    })
    formAction(formData)
  }

  return (
    <Box sx={{ width: '700px', margin: '0 auto', marginTop: '5px' }}>
      <Box sx={{ marginBottom: '5px' }}>
        <Link href="/customers/list">
          <Button variant="text" size="small">
            {t('CustomerEdit.backButtonLabel')}
          </Button>
        </Link>
      </Box>

      <form action={handleFormSubmit}>
        <Box sx={{ marginBottom: '15px' }}>
          <CustomerName
            value={customer?.name ?? customerName}
            validationError={validationError}
            setValidationError={setValidationError}
          />
        </Box>

        <Box sx={{ marginBottom: '5px' }}>
          <ApiKey value={customer?.apiKey} disabled={!customer} />
        </Box>

        <Typography variant="body1" sx={{ marginBottom: '5px' }}>
          {t('CustomerEdit.permissionLabel')}
        </Typography>

        <Box sx={{ marginBottom: '5px' }}>
          {typesData && (
            <Types
              validationError={validationError}
              setValidationError={setValidationError}
              typesData={typesData}
              setTypesData={setTypesData}
            />
          )}
        </Box>

        <Box sx={{ marginTop: '10px', textAlign: 'right' }}>
          <Button variant="contained" type="submit" sx={{ marginRight: customer ? '10px' : '' }}>
            {t('Common.saveButtonLabel')}
          </Button>
          {customer && (
            <ConfirmableButton
              title={t('CustomerEdit.confirmDeleteTitle')}
              content={t('CustomerEdit.confirmDeleteContent', {
                name: customer.name,
              })}
              okLabel={t('Common.agreeButtonLabel')}
              cancelLabel={t('Common.denyButtonLabel')}
              onContinue={onDeleteDialogOk}
            >
              {t('Common.deleteButtonLabel')}
            </ConfirmableButton>
          )}
        </Box>
      </form>
    </Box>
  )
}
