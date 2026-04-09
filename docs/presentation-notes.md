# Presentation Notes

## Slide 1. Title

**Bank Statement Converter**  
Zakhar Podyakov  
usfuld@gmail.com  
Group: [fill your group here]

## Slide 2. Context

**End user**

- Accountants and bookkeepers
- Finance admins and operations teams
- Accounting, financial, and legal firms working with PDF bank statements

**Problem**

PDF bank statements are difficult to use in bookkeeping, reconciliation, and review workflows. Manual transfer into Excel or CSV is repetitive, slow, and error-prone.

**One-sentence product idea**

Bank Statement Converter turns PDF bank statements into structured exports for accounting workflows.

## Slide 3. Implementation

**How I built it**

- Frontend: SvelteKit + TypeScript
- Backend: Ruby on Rails API
- Database: PostgreSQL
- Auth: Google OAuth
- API docs: OpenAPI + Scalar
- Deployment: Ubuntu VM + nginx + systemd
- Used LLMs and agents throughout planning, implementation, debugging, deployment, and polish

**Version 1**

- Google sign-in
- PDF upload
- statement conversion
- export to CSV / JSON

**Version 2**

- automatic processing after upload
- editable preview table
- conversion history with search and filters
- personal API key
- code examples in profile
- public API docs
- polished production deployment

**TA feedback addressed**

- made the flow more complete and usable
- improved product polish
- added API support and documentation for workflow automation

## Slide 4. Demo

**Voice-over script for the 2-minute video**

“This is Bank Statement Converter. The goal of the product is to help accountants and finance operations teams turn PDF bank statements into structured data they can actually use.

I start on the main convert page. After signing in, the user can upload one or more PDF bank statements. The system processes them automatically and adds them to conversion history.

In the history table, the user can search previous uploads, filter by status, and download exports. If needed, they can open preview mode before downloading.

Here I open a conversion preview. The parsed rows are shown in a table where the user can review and edit the extracted transaction data before export.

The profile page also gives each user a personal API key. This makes the product useful not only through the web interface, but also for accounting workflows that need automation or integrations.

Finally, I open the API documentation page. The API is documented with OpenAPI and Scalar, so the product is easier to understand, test, and integrate.

So the final result is a deployed full-stack utility SaaS for accounting workflows, with a frontend, backend, database, authentication, API access, and public documentation.”

## Slide 5. Links

Add these two links and generate QR codes for them:

- GitHub repo: `https://github.com/p0dyakov/se-toolkit-hackathon`
- Deployed product: `https://statementconverter.ru`

Optional additional link:

- API docs: `https://docs.statementconverter.ru`

Prepared QR files in the project:

- `docs/qr/github-repo.png`
- `docs/qr/deployed-product.png`
- `docs/qr/api-docs.png`
