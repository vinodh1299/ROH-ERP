const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');
const http = require('http');

async function getLoginData(email, password) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({ email, password });
    const req = http.request('http://127.0.0.1:8000/api?action=login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

const PORTALS = [
  {
    role: 'director',
    name: 'Director',
    creds: ['director@roh.com', 'director123'],
    outDir: path.join(__dirname, '../SCREEN SHOTS/Director'),
    tabs: [
      { tab: 0, file: '01_Director_Dashboard.png', title: 'Dashboard' },
      { tab: 1, file: '02_Director_Master_Schedule.png', title: 'Master Schedule' },
      { tab: 2, file: '03_Director_Therapists.png', title: 'Therapist Section' },
      { tab: 3, file: '04_Director_Students.png', title: 'Students Section' },
      { tab: 4, file: '05_Director_Stud_Progress.png', title: 'Student Progress' },
      { tab: 5, file: '06_Director_IEP_Reports.png', title: 'IEP Reports' },
      { tab: 6, file: '07_Director_Settings.png', title: 'Settings' },
    ]
  },
  {
    role: 'admin',
    name: 'Admin',
    creds: ['admin@roh.com', 'admin123'],
    outDir: path.join(__dirname, '../SCREEN SHOTS/Admin'),
    tabs: [
      { tab: 0, file: '01_Admin_Dashboard.png', title: 'Dashboard' },
      { tab: 1, file: '02_Admin_Director_Calendar.png', title: 'Director Calendar' },
      { tab: 2, file: '03_Admin_Therapists.png', title: 'Therapists' },
      { tab: 3, file: '04_Admin_Students.png', title: 'Students' },
      { tab: 4, file: '05_Admin_Stud_Progress.png', title: 'Student Progress' },
      { tab: 5, file: '06_Admin_IEP_Reports.png', title: 'IEP Reports' },
      { tab: 6, file: '07_Admin_Settings.png', title: 'Settings' },
    ]
  },
  {
    role: 'therapist',
    name: 'Therapist',
    creds: ['therapist@roh.com', 'therapist123'],
    outDir: path.join(__dirname, '../SCREEN SHOTS/Therapist'),
    tabs: [
      { tab: 0, file: '01_Therapist_Dashboard.png', title: 'Dashboard' },
      { tab: 1, file: '02_Therapist_Timetable.png', title: 'Timetable' },
      { tab: 2, file: '03_Therapist_Milestone_Assessment.png', title: 'Milestone Assessment' },
      { tab: 3, file: '04_Therapist_Barriers_Assessment.png', title: 'Barriers Assessment' },
      { tab: 4, file: '05_Therapist_Transition_Assessment.png', title: 'Transition Assessment' },
      { tab: 5, file: '06_Therapist_EES_Assessment.png', title: 'EES Assessment' },
      { tab: 6, file: '07_Therapist_Preference_Assessment.png', title: 'Preference Assessment' },
      { tab: 7, file: '08_Therapist_VB_MAPP_Report.png', title: 'VB-MAPP Report' },
      { tab: 8, file: '09_Therapist_IEP.png', title: 'IEP' },
      { tab: 9, file: '10_Therapist_Daily_Data_Sheet.png', title: 'Daily Data Sheet' },
      { tab: 10, file: '11_Therapist_Profile.png', title: 'Profile' },
    ]
  },
  {
    role: 'parent',
    name: 'Parent',
    creds: ['parent@roh.com', 'parent123'],
    outDir: path.join(__dirname, '../SCREEN SHOTS/Parent'),
    tabs: [
      { tab: 0, file: '01_Parent_Dashboard.png', title: 'Dashboard' },
      { tab: 1, file: '02_Parent_Progress_Reports.png', title: 'Progress Reports' },
      { tab: 2, file: '03_Parent_IEP_Goal_Data.png', title: 'IEP Goal Data' },
      { tab: 3, file: '04_Parent_Graphs.png', title: 'Graphs' },
      { tab: 4, file: '05_Parent_Profile.png', title: 'Profile' },
    ]
  }
];

async function run() {
  console.log('Starting high-resolution portal screenshot automation...');
  const browser = await puppeteer.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-web-security',
      '--window-size=1600,1050',
    ],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1600, height: 1050, deviceScaleFactor: 2 });

  for (const portal of PORTALS) {
    console.log(`\n========================================`);
    console.log(`🚀 Starting Portal: ${portal.name} (${portal.tabs.length} screens)`);
    console.log(`========================================`);
    if (!fs.existsSync(portal.outDir)) {
      fs.mkdirSync(portal.outDir, { recursive: true });
    }

    const loginRes = await getLoginData(portal.creds[0], portal.creds[1]);
    console.log(`Authenticated as: ${loginRes.name} [${loginRes.role}]`);

    // Pre-seed localStorage for this user
    await page.goto('http://127.0.0.1:8080/');
    await page.evaluate((user) => {
      localStorage.clear();
      const map = {
        'is_logged_in': 'true',
        'user_id': String(user.id),
        'user_name': user.name,
        'user_email': user.email,
        'user_role': user.role,
        'jwt_token': user.token,
        'auth_token': user.token,
      };
      for (const [k, v] of Object.entries(map)) {
        localStorage.setItem(k, v);
      }
    }, loginRes);

    for (const item of portal.tabs) {
      const url = `http://127.0.0.1:8080/#/${portal.role}?tab=${item.tab}`;
      console.log(`[${portal.name}] Capturing tab ${item.tab} (${item.title}) → ${url}`);
      await page.goto(url, { waitUntil: 'networkidle2' });
      await page.reload({ waitUntil: 'networkidle2' });
      
      // Wait for Flutter canvas render + API data resolution
      await new Promise(r => setTimeout(r, 3200));

      const outPath = path.join(portal.outDir, item.file);
      await page.screenshot({ path: outPath });
      console.log(`  ✓ Saved: ${item.file}`);
    }
  }

  await browser.close();
  console.log('\n🎉 ALL SCREENSHOTS COMPLETED SUCCESSFULLY!');
}

run().catch(err => {
  console.error('Fatal execution error:', err);
  process.exit(1);
});
