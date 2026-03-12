export interface VerificationEmailData {
  name: string;
  verificationUrl: string;
  appName: string;
}

export function verificationEmailTemplate(
  data: VerificationEmailData,
): string {
  const { name, verificationUrl, appName } = data;

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Verify Your Email</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td style="padding: 40px 20px;">
        <table role="presentation" style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
          <tr>
            <td style="padding: 40px 30px; text-align: center;">
              <h1 style="margin: 0 0 20px 0; color: #333333; font-size: 28px; font-weight: 600;">
                Verify Your Email Address
              </h1>
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                Hi ${name},
              </p>
              <p style="margin: 0 0 30px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                Thank you for signing up for ${appName}! Please verify your email address by clicking the button below.
              </p>
              <table role="presentation" style="margin: 0 auto;">
                <tr>
                  <td style="background-color: #14b8a6; border-radius: 6px;">
                    <a href="${verificationUrl}" style="display: inline-block; padding: 14px 32px; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 6px;">
                      Verify Email Address
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin: 30px 0 0 0; color: #999999; font-size: 14px; line-height: 1.6;">
                Or copy and paste this link into your browser:
              </p>
              <p style="margin: 10px 0 0 0; color: #14b8a6; font-size: 14px; word-break: break-all;">
                ${verificationUrl}
              </p>
              <p style="margin: 40px 0 0 0; color: #999999; font-size: 12px; line-height: 1.6;">
                This link will expire in 24 hours. If you didn't create an account with ${appName}, you can safely ignore this email.
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

