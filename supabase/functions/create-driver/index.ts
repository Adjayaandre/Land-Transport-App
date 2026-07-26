import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const allowedRoles = new Set(["driver", "admin", "superadmin", "karyawan"]);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Unauthorized" }, 401);
    }

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );

    const {
      data: { user: caller },
      error: userError,
    } = await supabaseUser.auth.getUser();

    if (userError || !caller) {
      return json({ error: "Unauthorized" }, 401);
    }

    const { data: profile, error: profileError } = await supabaseUser
      .from("pengguna")
      .select("peran")
      .eq("id", caller.id)
      .maybeSingle();

    if (profileError || profile?.peran !== "superadmin") {
      return json({ error: "Hanya superadmin yang dapat menambah pengguna." }, 403);
    }

    const body = await req.json();
    const nama = (body.nama as string | undefined)?.trim();
    const email = (body.email as string | undefined)?.trim().toLowerCase();
    const password = body.password as string | undefined;
    const peran = (body.peran as string | undefined)?.trim().toLowerCase() ??
      "driver";

    if (!nama || !email || !password) {
      return json({ error: "Nama, email, dan password wajib diisi." }, 400);
    }

    if (!allowedRoles.has(peran)) {
      return json({ error: "Role pengguna tidak valid." }, 400);
    }

    if (password.length < 6) {
      return json({ error: "Password minimal 6 karakter." }, 400);
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: created, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          nama_lengkap: nama,
          peran,
        },
      });

    if (createError || !created.user) {
      return json({ error: createError?.message ?? "Gagal membuat akun pengguna." }, 400);
    }

    const userId = created.user.id;

    const { error: insertError } = await supabaseAdmin.from("pengguna").upsert(
      {
        id: userId,
        nama_lengkap: nama,
        peran,
        aktif: true,
      },
      { onConflict: "id" },
    );

    if (insertError) {
      await supabaseAdmin.auth.admin.deleteUser(userId);
      return json(
        { error: `Profil pengguna gagal disimpan: ${insertError.message}` },
        500,
      );
    }

    return json({ id: userId, nama, email, peran }, 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Internal server error";
    return json({ error: message }, 500);
  }
});

function json(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
