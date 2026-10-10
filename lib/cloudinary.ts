import { CLOUDINARY_CLOUD_NAME, CLOUDINARY_UPLOAD_PRESET } from '@/lib/config'

// Upload a file to Cloudinary using an *unsigned* upload preset.
// "Unsigned" means we never put a secret key in the browser.
// Set the cloud name + preset name in lib/config.ts.

export async function uploadToCloudinary(file: File, folder: string): Promise<string> {
  const formData = new FormData()
  formData.append('file', file)
  formData.append('upload_preset', CLOUDINARY_UPLOAD_PRESET)
  formData.append('folder', folder)

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload`,
    { method: 'POST', body: formData }
  )

  if (!response.ok) {
    const err = await response.json()
    throw new Error(err.error?.message ?? 'Upload failed')
  }

  const data = await response.json()
  return data.secure_url
}
