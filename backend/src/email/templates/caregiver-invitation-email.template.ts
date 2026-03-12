export interface CaregiverInvitationEmailData {
  inviteCode: string;
  patientName: string;
  relationship: string;
  registrationUrl: string;
  appName: string;
}

export function caregiverInvitationEmailTemplate(
  data: CaregiverInvitationEmailData,
): string {
  const { inviteCode, patientName, relationship, registrationUrl, appName } =
    data;

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Caregiver Invitation</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td style="padding: 40px 20px;">
        <table role="presentation" style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
          <tr>
            <td style="padding: 40px 30px; text-align: center;">
              <h1 style="margin: 0 0 20px 0; color: #333333; font-size: 28px; font-weight: 600;">
                You've Been Invited!
              </h1>
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                ${patientName} has invited you to be their caregiver on ${appName}.
              </p>
              <p style="margin: 0 0 30px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                As a caregiver, you'll be able to help manage ${patientName}'s health, medications, and appointments. Click the button below to accept the invitation and create your account.
              </p>
              <table role="presentation" style="margin: 0 auto;">
                <tr>
                  <td style="background-color: #14b8a6; border-radius: 6px;">
                    <a href="${registrationUrl}" style="display: inline-block; padding: 14px 32px; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 6px;">
                      Accept Invitation
                    </a>
                  </td>
                </tr>
              </table>
              <div style="margin: 30px 0; padding: 20px; background-color: #f9fafb; border-radius: 6px; text-align: left;">
                <p style="margin: 0 0 10px 0; color: #666666; font-size: 14px; font-weight: 600;">
                  Your Invitation Code:
                </p>
                <p style="margin: 0; color: #14b8a6; font-size: 24px; font-weight: 700; font-family: monospace; letter-spacing: 2px;">
                  ${inviteCode}
                </p>
                <p style="margin: 10px 0 0 0; color: #999999; font-size: 12px; line-height: 1.6;">
                  You'll need this code when registering. Or simply click the button above to register automatically.
                </p>
              </div>
              <p style="margin: 30px 0 0 0; color: #999999; font-size: 12px; line-height: 1.6;">
                This invitation will expire in 7 days. If you didn't expect this invitation, you can safely ignore this email.
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

