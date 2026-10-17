Apex Velocity Racing | SQL and Power BI Analytics

End-to-end motorsport and business intelligence project exploring racing performance, vehicle reliability, merchandise sales, and customer behavior.

WHY I BUILT THIS

I wanted a portfolio project that combined three things I’m genuinely interested in: cars, healthcare, and fashion. Apex Velocity Racing is a fictional motorsport team that owns cars and drivers, runs a driver and crew health program, and sells its own merch line, three business areas in one database instead of a single flat sales table.

All data is synthetic, generated with a Python script and a fixed random seed, with real patterns (like fitness affecting lap pace, or merch sales spiking after a win) built in on purpose so the SQL analysis had something real to find.

TOOLS AND TECHNOLOGIES

PostgreSQL and pgAdmin: database design and SQL execution
SQL: CTEs, window functions, joins, and aggregate queries
Microsoft Power BI: dashboard design, DAX measures, KPI cards, slicers
Python: synthetic data generation
GitHub: project documentation and version control

BUSINESS QUESTIONS AND FINDINGS

Does driver fitness affect lap pace?
Drivers scoring 75+ on fitness checks ran at race average pace and finished about 1 position better than the 65 to 74 band.
Which components fail most, and what do they cost?
Engines caused the costliest failures, $265K average, and every category’s failure rate roughly doubled in wet conditions.
Does weather or chassis age predict a DNF?
Weather had a clear effect, 22% DNF rate in dry versus 33 to 38% in wet or mixed. Chassis age showed no meaningful trend.
Is the team improving season over season?
Points rose 124% from 2023 to 2024 and kept climbing into 2025.
How often does a failed medical check bench a driver?
Every failed clearance led to a swap, and the reserve driver scored about 30% of the points the primaries did.
Do merch sales spike after a win?
Orders peaked at 34 per day in the 2 days after a win, nearly 3 times the pre-win baseline of 11 per day.
How fast do limited drops sell versus core lines?
Limited drops earned $332.58 per day per product versus $106.17 per day for core lines in their first 3 weeks.
Which categories get returned most, and why?
Sneakers returned most at 14.9%, mostly for sizing. Accessories and caps returned least and mostly for changed mind.
Which regions and customers generate the most value?
North America drove the most total revenue at $700K. The top 10 customers were identified for targeted outreach.

HOW I WORKED THROUGH IT

Explored the data model. Mapped out how racing, health, and merch data would need to connect through a shared race calendar before writing a single query.
Wrote the SQL. Nine queries in PostgreSQL, using CTEs, window functions, and joins to answer the questions above, each one tested against the live database before I trusted the numbers.
Exported the results. Query outputs saved as CSVs to keep a record of what the database actually returned.
Built the dashboard. Four Power BI pages, Racing Performance, Driver and Team Performance, Race Wins and Commercial Impact, Merchandise and Customer Insights, with a consistent color system where red flags risk and navy or blue flags performance.
Interpreted the results. Framed every finding around a real business decision, not just a number on a chart.

POWER BI DASHBOARD

Four pages covering racing performance, driver health, commercial impact around race wins, and merchandise and customer insights. Dashboard files are in the dashboard folder, including the Power BI pbix file and screenshots of each page.

PROJECT FILES

sql-queries folder: all 9 analysis queries
data folder: exported SQL query results in CSV format
dashboard folder: Power BI report and dashboard screenshots

SKILLS DEMONSTRATED

SQL querying and relational data modeling
Data exploration and preparation
KPI development and performance measurement
Power BI dashboard design and DAX
Analytical problem solving
Data visualization and storytelling
Translating business questions into technical analysis

ABOUT ME

Built by Lazourde Alshafie, Business Intelligence Technology student at the University of North Florida.
