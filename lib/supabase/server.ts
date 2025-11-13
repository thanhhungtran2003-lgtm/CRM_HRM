// File: lib/supabase/server.ts (Fixed cookies handling for Next.js 15 App Router)

import { createBrowserClient } from "@supabase/auth-helpers-nextjs";
import { cookies } from "next/headers";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

/**
 * Creates a Supabase Client for Server Components and Route Handlers.
 * Uses createBrowserClient pattern to avoid async/await issues with cookies in Next.js 15.
 */
export const createSupabaseServerClient = () => {
  const cookieStore = cookies();

  return createBrowserClient(supabaseUrl, supabaseAnonKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options);
          });
        } catch {
          // Handle the error silently in server context
        }
      },
    },
  });
};
