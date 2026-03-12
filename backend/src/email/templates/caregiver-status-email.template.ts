export interface CaregiverStatusEmailData {
  patientName: string;
  status: 'enabled' | 'disabled';
  appName: string;
}

export function caregiverStatusEmailTemplate(
  data: CaregiverStatusEmailData,
): string {
  const { patientName, status, appName } = data;
  const isEnabled = status === 'enabled';

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Caregiver Access Update</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td style="padding: 40px 20px;">
        <table role="presentation" style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
          <tr>
            <td style="padding: 40px 30px; text-align: center;">
              <h1 style="margin: 0 0 20px 0; color: #333333; font-size: 28px; font-weight: 600;">
                Access ${isEnabled ? 'Restored' : 'Revoked'}
              </h1>
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                This is to inform you that your caregiver access for **${patientName}** has been ${status}.
              </p>
              ${
                isEnabled
                  ? `
              <p style="margin: 0 0 30px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                You can now log back into the app and continue managing ${patientName}'s care.
              </p>
              <table role="presentation" style="margin: 0 auto;">
                <tr>
                  <td style="background-color: #14b8a6; border-radius: 6px;">
                    <a href="https://${appName.toLowerCase().replace(' ', '')}.app/login" style="display: inline-block; padding: 14px 32px; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 6px;">
                      Log In to App
                    </a>
                  </td>
                </tr>
              </table>
              `
                  : `
              <p style="margin: 0 0 30px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                Your account is still active, but you can no longer view or manage ${patientName}'s information. If you believe this is a mistake, please reach out to ${patientName} directly.
              </p>
              `
              }
              <p style="margin: 30px 0 0 0; color: #999999; font-size: 12px; line-height: 1.6;">
                This is an automated notification from ${appName}. Please do not reply to this email.
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
