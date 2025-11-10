import { FormControl, OutlinedInput, FormHelperText } from '@mui/material'

type CsvProps = {
  id: string
  name: string
  onChange: (event: React.ChangeEvent<HTMLInputElement>) => void
  helperText?: string
  errorMessage?: string | null
}

export function Csv({ id, name, onChange, helperText, errorMessage }: CsvProps) {
  return (
    <FormControl variant="standard">
      <OutlinedInput
        id={id}
        name={name}
        type="file"
        className="MuiOutlinedInput-inputSizeSmall"
        size="small"
        sx={{
          width: '620px',
          input: {
            paddingBottom: '11.5px',
            paddingTop: '5.5px',
          },
        }}
        slotProps={{
          input: {
            accept: '.csv',
          },
        }}
        onChange={onChange}
        error={!!errorMessage}
      />
      {!!errorMessage && <FormHelperText error={!!errorMessage}>{errorMessage}</FormHelperText>}
      {!!helperText && <FormHelperText>{helperText}</FormHelperText>}
    </FormControl>
  )
}
