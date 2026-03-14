export interface ForgotPasswordEmailData {
    name: string;
    code: string;
    appName: string;
}

export function forgotPasswordEmailTemplate(
    data: ForgotPasswordEmailData,
): string {
    const { name, code, appName } = data;

    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Your Password</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td style="padding: 40px 20px;">
        <table role="presentation" style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
          <tr>
            <td style="padding: 40px 30px; text-align: center;">
              <h1 style="margin: 0 0 20px 0; color: #333333; font-size: 28px; font-weight: 600;">
                Reset Your Password
              </h1>
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                Hi ${name},
              </p>
              <p style="margin: 0 0 30px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                We received a request to reset your password. Use the verification code below to complete the process:
              </p>
              <div style="margin: 0 auto; background-color: #f0fdfa; border: 2px dashed #14b8a6; border-radius: 8px; padding: 20px; display: inline-block;">
                <span style="font-size: 32px; font-weight: 700; color: #14b8a6; letter-spacing: 8px;">
                  ${code}
                </span>
              </div>
              <p style="margin: 40px 0 0 0; color: #999999; font-size: 12px; line-height: 1.6;">
                This code will expire in 15 minutes. If you didn't request a password reset, you can safely ignore this email.
              </p>
            </td>
          </tr>
        </table>
        <table role="presentation" style="max-width: 600px; margin: 20px auto 0;">
          <tr>
            <td style="text-align: center; padding: 20px; color: #999999; font-size: 12px;">
              <p style="margin: 0;">
                © ${new Date().getFullYear()} ${appName}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `.trim();
}
