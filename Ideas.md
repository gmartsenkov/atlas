access key: f5f1c90ff6e71af679e575d70c547125
secret key: 3d829e5991d94bfce135ca033cc05c1e6bd3ea2146cfe5ccab744c38e54cf58c
export SUPABASE_URL=https://cpiidsiatlhtreyxumnq.storage.supabase.co/storage/v1/s3
export SUPABASE_S3_ACCESS_KEY=f5f1c90ff6e71af679e575d70c547125
export SUPABASE_S3_SECRET_KEY=3d829e5991d94bfce135ca033cc05c1e6bd3ea2146cfe5ccab744c38e54cf58c
export SUPABASE_S3_REGION=eu-north-1

export S3_ENDPOINT=https://cpiidsiatlhtreyxumnq.supabase.co/storage/v1/s3
export S3_PUBLIC_URL=https://cpiidsiatlhtreyxumnq.supabase.co/storage/v1/object/public
export S3_REGION=eu-north-1
export S3_ACCESS_KEY=f5f1c90ff6e71af679e575d70c547125
export S3_SECRET_KEY=3d829e5991d94bfce135ca033cc05c1e6bd3ea2146cfe5ccab744c38e54cf58c


# Ideas
- Community analytics dashboard — page views, popular sections, active contributors, search terms people use. Useful data that admins would pay for
- Version history depth — free gets last 30 days of page history, paid gets unlimited. The proposal system already tracks changes, so this
is natural
- Pinned/featured pages — community admins pay to pin important pages to a discovery feed or cross-community homepage
- Advanced proposal workflows — requiring multiple approvals, scheduled publishing, draft collaboration. Free gets simple approve/reject
- Content health reports — flag stale pages, broken links, sections with no edits in months. Helps large communities maintain quality
- Certification/verified communities — a checkmark for communities that meet quality standards. Small annual fee, builds credibility
- Community templates — curated starter kits (e.g., "game wiki", "product docs", "neighborhood guide"). Free basics, paid premium ones
- Custom block types — sell or let third parties sell specialized BlockNote blocks (maps, polls, embedded databases, changelogs)


9. Test coverage for core business logic — There are zero tests for communities,
proposals, sections, comments, or search. Only auth is tested. This is the biggest
risk — any refactoring is flying blind without tests for the core domain.
