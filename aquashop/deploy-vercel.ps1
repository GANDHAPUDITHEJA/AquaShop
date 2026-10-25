$ErrorActionPreference = 'Stop'

flutter build web --release --base-href /
vercel deploy build/web --prod
