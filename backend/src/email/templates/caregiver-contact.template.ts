export const caregiverContactEmailTemplate = (data: {
  patientName: string;
  message: string;
  appName: string;
}) => `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Message from ${data.patientName}</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #008080; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { padding: 20px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 8px 8px; }
        .patient-name { font-weight: bold; color: #008080; }
        .message-box { background-color: #f9f9f9; padding: 15px; border-radius: 6px; border-left: 4px solid #008080; margin: 20px 0; }
        .footer { text-align: center; margin-top: 20px; font-size: 0.8em; color: #777; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Message from ${data.patientName}</h1>
    </div>
    <div class="content">
        <p>Hello,</p>
        <p><span class="patient-name">${data.patientName}</span> has sent you a message via the <strong>${data.appName}</strong> application:</p>
        
        <div class="message-box">
            ${data.message.replace(/\n/g, '<br>')}
        </div>
        
        <p>Please respond to them at your earliest convenience.</p>
        
        <p>Best regards,<br>The ${data.appName} Team</p>
    </div>
    <div class="footer">
        &copy; ${new Date().getFullYear()} ${data.appName}. All rights reserved.
    </div>
</body>
</html>
`;
