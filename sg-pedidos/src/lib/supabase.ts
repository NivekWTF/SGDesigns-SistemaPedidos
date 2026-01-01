import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

if (!supabaseUrl || !supabaseAnonKey) {
	const missing: string[] = []
	if (!supabaseUrl) missing.push('VITE_SUPABASE_URL')
	if (!supabaseAnonKey) missing.push('VITE_SUPABASE_ANON_KEY')

	throw new Error([
		`Missing Supabase env var(s): ${missing.join(', ')}`,
		'',
		'Create a `.env` file in the `sg-pedidos/` folder with these lines:',
		'VITE_SUPABASE_URL=https://your-project.supabase.co',
		'VITE_SUPABASE_ANON_KEY=your-anon-key',
		'',
		'Then restart the dev server (stop + `npm run dev`).'
	].join('\n'))
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
