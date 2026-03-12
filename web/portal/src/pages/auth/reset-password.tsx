import { useState, type FormEvent, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ThemeToggle } from "@/components/theme-toggle"
import { ShieldCheck, AlertCircle, Loader2, CheckCircle2, Lock } from "lucide-react"
import { Link, useNavigate, useSearchParams } from "react-router-dom"
import { useAuth } from "@/contexts/auth-context"
import { ApiClientError } from "@/lib/api/client"

export default function ResetPasswordPage() {
  const [searchParams] = useSearchParams()
  const token = searchParams.get("token")
  const navigate = useNavigate()
  
  const [password, setPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [error, setError] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSubmitted, setIsSubmitted] = useState(false)
  const { resetPassword } = useAuth()

  useEffect(() => {
    if (!token) {
      setError("Invalid or missing reset token. Please request a new link.")
    }
  }, [token])

  const validateForm = (): boolean => {
    setError(null)

    if (!password) {
      setError("Password is required")
      return false
    }

    if (password.length < 8) {
      setError("Password must be at least 8 characters")
      return false
    }

    if (password !== confirmPassword) {
      setError("Passwords do not match")
      return false
    }

    return true
  }

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setError(null)

    if (!token) {
      setError("Invalid or missing reset token.")
      return
    }

    if (!validateForm()) {
      return
    }

    setIsSubmitting(true)

    try {
      await resetPassword(token, password)
      setIsSubmitted(true)
      // Redirect to login after a short delay
      setTimeout(() => {
        navigate("/login")
      }, 3000)
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
          {!isSubmitted ? (
            <>
              <div>
                <h1 className="text-2xl font-semibold leading-tight text-foreground flex items-center gap-2">
                  <Lock className="size-5" />
                  Set new password
                </h1>
                <p className="mt-2 text-sm text-muted-foreground">
                  Choose a secure password for your account. Min 8 characters required.
                </p>
              </div>
              <form onSubmit={handleSubmit} className="space-y-4">
                {error && (
                  <div className="flex items-center gap-2 rounded-lg border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive">
                    <AlertCircle className="size-4 shrink-0" />
                    <span>{error}</span>
                  </div>
                )}
                <div className="space-y-2">
                  <Label htmlFor="password">New Password</Label>
                  <Input
                    id="password"
                    type="password"
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    disabled={isSubmitting || !token}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="confirmPassword">Confirm New Password</Label>
                  <Input
                    id="confirmPassword"
                    type="password"
                    placeholder="••••••••"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    disabled={isSubmitting || !token}
                    required
                  />
                </div>
                <Button type="submit" className="w-full" disabled={isSubmitting || !token}>
                  {isSubmitting ? (
                    <>
                      <Loader2 className="mr-2 size-4 animate-spin" />
                      Updating password...
                    </>
                  ) : (
                    "Reset Password"
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
                <h2 className="text-xl font-semibold">Password updated</h2>
                <p className="text-sm text-muted-foreground">
                  Your password has been reset successfully. Redirecting you to login...
                </p>
              </div>
              <Button asChild className="mt-2 w-full">
                <Link to="/login">Login Now</Link>
              </Button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
