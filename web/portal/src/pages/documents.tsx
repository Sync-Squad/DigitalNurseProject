import { useMemo, useState } from "react"
import { useDocumentsData } from "@/hooks/use-documents-data"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Download, Filter, Upload } from "lucide-react"

export default function DocumentsPage() {
  const [search, setSearch] = useState("")
  const [visibility, setVisibility] = useState<"all" | "Team" | "Caregiver" | "Private">(
    "all"
  )
  const { documents, loading, error } = useDocumentsData()

  const filteredDocuments = useMemo(() => {
    return documents.filter((doc) => {
      const matchesVisibility = visibility === "all" || doc.visibility === visibility
      const matchesSearch =
        search.length === 0 ||
        doc.type.toLowerCase().includes(search.toLowerCase()) ||
        doc.patient.toLowerCase().includes(search.toLowerCase())
      return matchesVisibility && matchesSearch
    })
  }, [visibility, search])

  return (
    <section className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-semibold tracking-tight">
            Document Library
          </h1>
          <p className="text-sm text-muted-foreground">
            Review, classify, and share patient documents securely.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" className="gap-2">
            <Filter className="size-4" />
            Saved views
          </Button>
          <Button className="gap-2">
            <Upload className="size-4" />
            Upload document
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <CardTitle className="text-sm font-semibold text-muted-foreground">
              Filters
            </CardTitle>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <Input
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search patient or document type"
              className="md:w-72"
            />
            <Select
              value={visibility}
              onValueChange={(value) =>
                setVisibility(value as typeof visibility)
              }
            >
              <SelectTrigger className="w-36">
                <SelectValue placeholder="Visibility" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All visibility</SelectItem>
                <SelectItem value="Team">Team</SelectItem>
                <SelectItem value="Caregiver">Caregiver</SelectItem>
                <SelectItem value="Private">Private</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent className="overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Patient</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Author</TableHead>
                <TableHead>Created</TableHead>
                <TableHead>Visibility</TableHead>
                <TableHead>Status</TableHead>
                <TableHead />
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredDocuments.map((doc) => (
                <TableRow key={doc.id}>
                  <TableCell className="font-medium">{doc.patient}</TableCell>
                  <TableCell>{doc.type}</TableCell>
                  <TableCell>{doc.author}</TableCell>
                  <TableCell>{doc.createdAt}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{doc.visibility}</Badge>
                  </TableCell>
                  <TableCell>
                    <Badge variant="secondary">{doc.status}</Badge>
                  </TableCell>
                  <TableCell>
                    <Button variant="ghost" size="sm" className="gap-1">
                      <Download className="size-3.5" />
                      Download
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          {loading ? (
            <div className="rounded-lg border border-dashed border-border/60 py-10 text-center text-sm text-muted-foreground">
              Loading documents...
            </div>
          ) : filteredDocuments.length === 0 ? (
            <div className="rounded-lg border border-dashed border-border/60 py-10 text-center text-sm text-muted-foreground">
              No documents found for the selected filters.
            </div>
          ) : null}
        </CardContent>
      </Card>

      {error ? (
        <div className="rounded-lg border border-destructive/40 bg-destructive/5 p-4 text-sm text-destructive">
          {error}
        </div>
      ) : null}
    </section>
  )
}

