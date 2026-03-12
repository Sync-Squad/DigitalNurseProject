import { useState, type FormEvent } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { ThemeToggle } from "@/components/theme-toggle"
import { ShieldCheck, SmartphoneNfc, AlertCircle, Loader2 } from "lucide-react"
import { Link, useNavigate, useLocation } from "react-router-dom"
import { useAuth } from "@/contexts/auth-context"
import { ApiClientError } from "@/lib/api/client"

export default function LoginPage() {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [rememberDevice, setRememberDevice] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const { login, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  // Redirect if already authenticated
  if (isAuthenticated) {
    const from = (location.state as { from?: Location })?.from?.pathname || "/"
    navigate(from, { replace: true })
    return null
  }

  const validateForm = (): boolean => {
    setError(null)

    if (!email.trim()) {
      setError("Email is required")
      return false
    }

    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email)) {
      setError("Please enter a valid email address")
      return false
    }

    if (!password) {
      setError("Password is required")
      return false
    }

    if (password.length < 8) {
      setError("Password must be at least 8 characters")
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
      await login(email.trim(), password)
      // Navigation happens automatically in auth context
      // But we can also get the intended destination from location.state
      const from = (location.state as { from?: Location })?.from?.pathname || "/"
      navigate(from, { replace: true })
    } catch (err) {
      if (err instanceof ApiClientError) {
        // Handle specific API errors
        if (err.status === 401) {
          setError("Invalid email or password. Please try again.")
        } else if (err.status === 0) {
          setError("Network error: Please check your connection and try again.")
        } else {
          // Check for email verification error message
          const errorMessage = err.data?.message || err.message
          if (errorMessage?.toLowerCase().includes("verify")) {
            setError(
              "Please verify your email address before logging in. Check your inbox for the verification email."
            )
          } else {
            setError(errorMessage || "An error occurred during login. Please try again.")
          }
        }
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
      <div className="mx-auto flex w-full max-w-5xl flex-1 flex-col gap-6 px-6 pb-12 pt-4 md:flex-row">
        <div className="flex flex-1 flex-col justify-center gap-6 rounded-2xl border border-border/60 bg-card/60 p-8 shadow-sm backdrop-blur">
          <div>
            <h1 className="text-3xl font-semibold leading-tight">
              Welcome back, Care Team
            </h1>
            <p className="mt-2 text-sm text-muted-foreground">
              Log in with your organizational email. Multi-factor authentication
              follows after successful credential verification.
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
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={isSubmitting}
                required
              />
            </div>
            <div className="flex items-center justify-between text-sm">
              <label className="flex items-center gap-2 text-muted-foreground">
                <Switch
                  id="remember"
                  checked={rememberDevice}
                  onCheckedChange={setRememberDevice}
                  disabled={isSubmitting}
                />
                <span>Remember this device</span>
              </label>
              <Link
                to="/reset-password"
                className="font-medium text-primary hover:underline"
              >
                Forgot password?
              </Link>
            </div>
            <Button type="submit" className="w-full" disabled={isSubmitting}>
              {isSubmitting ? (
                <>
                  <Loader2 className="mr-2 size-4 animate-spin" />
                  Signing in...
                </>
              ) : (
                "Continue to Portal"
              )}
            </Button>
          </form>
          <p className="text-xs text-muted-foreground">
            Having trouble?{" "}
            <Link to="/support" className="underline underline-offset-4">
              Contact support
            </Link>
          </p>
        </div>
        <div className="flex flex-1 flex-col justify-center gap-6 rounded-2xl border border-border/60 bg-muted/30 p-8 shadow-sm">
          <div className="flex items-center gap-3 text-primary">
            <SmartphoneNfc className="size-5" />
            <span className="text-sm font-semibold uppercase tracking-[0.25em]">
              Secure Access
            </span>
          </div>
          <div className="space-y-4 text-sm text-muted-foreground">
            <p>
              The Digital Nurse portal mirrors the mobile experience with added
              desktop workflows tailored for administrators, providers, and care
              coordinators.
            </p>
            <p>
              MFA is enforced for all roles. After initial login you will be
              prompted for either an email OTP or authenticator app code.
            </p>
            <p>
              Access is governed by role-based permissions aligned with HIPAA/
              GDPR controls. Every critical action is logged in the audit trail.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

