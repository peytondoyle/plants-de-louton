#!/bin/bash

# Database Audit Script for Plants de Louton
# This script runs audit queries against your Supabase database

echo "🔍 Running Plants de Louton Database Audit..."
echo "============================================"

# You'll need to set these environment variables or replace with your values
SUPABASE_DB_URL="${SUPABASE_DB_URL:-postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres}"

# Run the audit queries
psql "$SUPABASE_DB_URL" < supabase/audit_queries.sql > audit_results.txt 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Audit complete! Results saved to audit_results.txt"
    echo ""
    echo "📊 Preview of results:"
    echo "----------------------"
    head -50 audit_results.txt
else
    echo "❌ Error running audit. Check your database connection."
    echo "Make sure SUPABASE_DB_URL is set correctly."
fi
