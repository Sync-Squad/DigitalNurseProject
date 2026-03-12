import { useEffect, useState } from "react"
import type { DocumentRecord } from "@/mocks/data"
import { api } from "@/lib/api/client"
import { API_ENDPOINTS } from "@/lib/api/config"

export function useDocumentsData(elderUserId?: string) {
  const [documents, setDocuments] = useState<DocumentRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let isMounted = true
    ;(async () => {
      try {
        setLoading(true)
        const endpoint = elderUserId
          ? `${API_ENDPOINTS.documents.list}?elderUserId=${elderUserId}`
          : API_ENDPOINTS.documents.list
        const response = await api.get<
          Array<{
            id: string
            type: string
            title?: string
            uploadDate: string
            visibility?: string
            userId?: string
            description?: string | null
          }>
        >(endpoint)

        if (!isMounted) return

        setDocuments(
          response.map((doc) => ({
            id: doc.id,
            patient: doc.userId ? `User ${doc.userId}` : "Unknown",
            type: (doc.type as DocumentRecord["type"]) || "Care Plan",
            author: doc.title || "Uploaded file",
            createdAt: new Date(doc.uploadDate).toLocaleString(),
            visibility: (doc.visibility as DocumentRecord["visibility"]) || "Private",
            status: (doc.description as DocumentRecord["status"]) || "Published",
          })),
        )
        setError(null)
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Unable to load documents"
        if (isMounted) setError(message)
      } finally {
        if (isMounted) setLoading(false)
      }
    })()

    return () => {
      isMounted = false
    }
  }, [elderUserId])

  return { documents, loading, error }
}

