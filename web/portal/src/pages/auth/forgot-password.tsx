import { useState, type FormEvent } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ThemeToggle } from "@/components/theme-toggle"
import { ShieldCheck, AlertCircle, Loader2, CheckCircle2, ArrowLeft } from "lucide-react"
import { Link } from "react-router-dom"
import { useAuth } from "@/contexts/auth-context"
import { ApiClientError } from "@/lib/api/client"

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState("")
  const [error, setError] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSubmitted, setIsSubmitted] = useState(false)
  const { forgotPassword } = useAuth()

  const validateForm = (): boolean => {
    setError(null)

    if (!email.trim()) {
      setError("Email is required")
      return false
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email)) {
      setError("Please enter a valid email address")
      return false
    }

    return true
  }

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setError(null)

    if (!validateForm()) {
      return
    }

    setIsSubmitting(true)

    try {
      await forgotPassword(email.trim())
      setIsSubmitted(true)
    } catch (err) {
      if (err instanceof ApiClientError) {
        setError(err.data?.message || err.message || "An error occurred. Please try again.")
      } else {
        setError("An unexpected error occurred. Please try again.")
      }
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-screen flex-col bg-gradient-to-br from-background via-background to-muted">
      <header className="flex items-center justify-between px-6 py-4">
        <div className="flex items-center gap-3">
          <ShieldCheck className="size-6 text-primary" />
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">
              Digital Nurse
            </p>
            <p className="text-base font-semibold tracking-tight">
              Care Portal Access
            </p>
          </div>
        </div>
        <ThemeToggle />
      </header>
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col justify-center px-6 pb-12 pt-4">
        <div className="flex flex-col gap-6 rounded-2xl border border-border/60 bg-card/60 p-8 shadow-sm backdrop-blur">
          <Link to="/login" className="flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors">
            <ArrowLeft className="size-4" />
            Back to login
          </Link>

          {!isSubmitted ? (
            <>
              <div>
                <h1 className="text-2xl font-semibold leading-tight">
                  Forgot password?
                </h1>
                <p className="mt-2 text-sm text-muted-foreground">
                  Enter your email address and we'll send you a link to reset your password.
                </p>
              </div>
              <form onSubmit={handleSubmit} className="space-y-6">
                {error && (
                  <div className="flex items-center gap-2 rounded-lg border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive">
                    <AlertCircle className="size-4 shrink-0" />
                    <span>{error}</span>
                  </div>
                )}
                <div className="space-y-2">
                  <Label htmlFor="email">Work Email</Label>
                  <Input
                    id="email"
                    type="email"
                    placeholder="you@digitalnurse.app"
                    autoComplete="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    disabled={isSubmitting}
                    required
                  />
                </div>
                <Button type="submit" className="w-full" disabled={isSubmitting}>
                  {isSubmitting ? (
                    <>
                      <Loader2 className="mr-2 size-4 animate-spin" />
                      Sending link...
                    </>
                  ) : (
                    "Send Reset Link"
                  )}
                </Button>
              </form>
            </>
          ) : (
            <div className="flex flex-col items-center text-center gap-4 py-4">
              <div className="flex size-12 items-center justify-center rounded-full bg-primary/10 text-primary">
                <CheckCircle2 className="size-6" />
              </div>
              <div className="space-y-2">
                <h2 className="text-xl font-semibold">Check your email</h2>
                <p className="text-sm text-muted-foreground">
                  If an account exists for <span className="font-medium text-foreground">{email}</span>, you will receive a password reset link shortly.
                </p>
              </div>
              <Button asChild className="mt-2 w-full">
                <Link to="/login">Return to Login</Link>
              </Button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
