-- RLS insert/select perjalanan untuk user login
ALTER TABLE public.perjalanan ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Auth insert perjalanan" ON public.perjalanan;
CREATE POLICY "Auth insert perjalanan"
  ON public.perjalanan
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id_driver);

DROP POLICY IF EXISTS "Auth read perjalanan" ON public.perjalanan;
CREATE POLICY "Auth read perjalanan"
  ON public.perjalanan
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Auth update own perjalanan" ON public.perjalanan;
CREATE POLICY "Auth update own perjalanan"
  ON public.perjalanan
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id_driver)
  WITH CHECK (auth.uid() = id_driver);
