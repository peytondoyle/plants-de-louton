#!/usr/bin/env node
import { SignJWT } from 'jose'

// Usage:
// APPLE_TEAM_ID=XXXX APPLE_KEY_ID=YYYY APPLE_CLIENT_ID=com.louton.plants APPLE_PRIVATE_KEY_PATH=./AuthKey_YYYY.p8 node scripts/generate-apple-client-secret.mjs

const {
  APPLE_TEAM_ID,
  APPLE_KEY_ID,
  APPLE_CLIENT_ID,
  APPLE_PRIVATE_KEY_PATH,
  APPLE_PRIVATE_KEY,
  EXP_MINUTES
} = process.env

if (!APPLE_TEAM_ID || !APPLE_KEY_ID || !APPLE_CLIENT_ID || (!APPLE_PRIVATE_KEY_PATH && !APPLE_PRIVATE_KEY)) {
  console.error('Missing required envs: APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_CLIENT_ID, and one of APPLE_PRIVATE_KEY_PATH or APPLE_PRIVATE_KEY')
  process.exit(1)
}

import fs from 'fs'

const privateKeyPem = APPLE_PRIVATE_KEY ?? fs.readFileSync(APPLE_PRIVATE_KEY_PATH, 'utf8')

// Apple requires ES256
import { importPKCS8 } from 'jose'
const alg = 'ES256'
const key = await importPKCS8(privateKeyPem, alg)

const now = Math.floor(Date.now() / 1000)
const exp = now + (parseInt(EXP_MINUTES || '20', 10) * 60) // default 20 minutes

const jwt = await new SignJWT({})
  .setProtectedHeader({ alg, kid: APPLE_KEY_ID })
  .setIssuer(APPLE_TEAM_ID)
  .setIssuedAt(now)
  .setExpirationTime(exp)
  .setAudience('https://appleid.apple.com')
  .setSubject(APPLE_CLIENT_ID)
  .sign(key)

console.log(jwt)


