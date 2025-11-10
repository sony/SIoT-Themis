import { registerDecorator, ValidationOptions, IsString, isLongitude, isLatitude } from 'class-validator'

export class RequestBodyDto {
  [key: string]: string
  @IsString()
  id: string

  @IsString()
  type: string
}

// eslint-disable-next-line @typescript-eslint/naming-convention
export function IsGeoJSONPoint(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'IsGeoJSONPoint',
      target: object.constructor,
      propertyName: propertyName,
      options: validationOptions,
      validator: {
        validate(value) {
          if (typeof value !== 'object' || value.type !== 'Point' || !Array.isArray(value.coordinates)) {
            return false
          }
          const [longitude, latitude] = value.coordinates
          return isLongitude(longitude) && isLatitude(latitude)
        },
        defaultMessage() {
          return `${propertyName} must be a valid GeoJSON Point`
        },
      },
    })
  }
}
