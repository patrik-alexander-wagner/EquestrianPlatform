--
-- PostgreSQL database dump
--

\restrict 62SZQOmAb7MycA8mX4T4cmFmcwO4T6cSrqOHR177ztrbSjjHpqhaTEvlTpMsaqG

-- Dumped from database version 16.14 (fce0ac2)
-- Dumped by pg_dump version 16.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: _system; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA _system;


--
-- Name: invoice_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.invoice_status AS ENUM (
    'DRAFT',
    'VET_VALIDATION',
    'STORES_VALIDATION',
    'FINANCE_VALIDATION',
    'APPROVED',
    'PUSHED_TO_ERP',
    'REJECTED'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'ADMIN',
    'LIVERY_ADMIN',
    'VETERINARY',
    'STORES',
    'FINANCE'
);


--
-- Name: validation_action; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.validation_action AS ENUM (
    'APPROVED',
    'REJECTED'
);


--
-- Name: validation_step; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.validation_step AS ENUM (
    'VET',
    'STORES',
    'FINANCE',
    'ADMIN_OVERRIDE'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: replit_database_migrations_v1; Type: TABLE; Schema: _system; Owner: -
--

CREATE TABLE _system.replit_database_migrations_v1 (
    id bigint NOT NULL,
    build_id text NOT NULL,
    deployment_id text NOT NULL,
    statement_count bigint NOT NULL,
    applied_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: replit_database_migrations_v1_id_seq; Type: SEQUENCE; Schema: _system; Owner: -
--

CREATE SEQUENCE _system.replit_database_migrations_v1_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: replit_database_migrations_v1_id_seq; Type: SEQUENCE OWNED BY; Schema: _system; Owner: -
--

ALTER SEQUENCE _system.replit_database_migrations_v1_id_seq OWNED BY _system.replit_database_migrations_v1.id;


--
-- Name: agreement_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agreement_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agreement_id uuid NOT NULL,
    filename text NOT NULL,
    file_data text NOT NULL,
    uploaded_at timestamp without time zone DEFAULT now()
);


--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_settings (
    key text NOT NULL,
    value text NOT NULL
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id text,
    username text,
    action text NOT NULL,
    entity_type text,
    entity_id text,
    details text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: billing_elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_elements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    horse_id uuid,
    customer_id uuid NOT NULL,
    box_id uuid,
    item_id uuid NOT NULL,
    quantity numeric DEFAULT '1'::numeric NOT NULL,
    base numeric,
    price numeric NOT NULL,
    transaction_date text NOT NULL,
    billed boolean DEFAULT false NOT NULL,
    invoice_id uuid,
    created_at timestamp without time zone DEFAULT now(),
    agreement_id uuid,
    billing_month text,
    user_id uuid
);


--
-- Name: boxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.boxes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type text DEFAULT 'box'::text NOT NULL,
    stable_id uuid NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    netsuite_id text
);


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    netsuite_id text,
    fullname text DEFAULT ''::text NOT NULL,
    is_inactive boolean DEFAULT false NOT NULL
);


--
-- Name: horse_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.horse_movements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agreement_id uuid,
    horse_id uuid NOT NULL,
    stablebox_id uuid NOT NULL,
    check_in text NOT NULL,
    check_out text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: horse_ownership; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.horse_ownership (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    horse_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: horses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.horses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    netsuite_id text,
    horse_name text NOT NULL,
    passport_name text,
    passport_number text,
    sex text,
    size text,
    color text,
    breed text,
    date_of_birth text,
    comments text,
    status text DEFAULT 'active'::text NOT NULL
);


--
-- Name: invoice_validations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_validations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    step text NOT NULL,
    action text NOT NULL,
    user_id uuid NOT NULL,
    comment text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    netsuite_id text,
    customer_id uuid NOT NULL,
    invoice_date text NOT NULL,
    total_amount numeric NOT NULL,
    status text DEFAULT 'DRAFT'::text NOT NULL,
    billing_month text,
    so_generated boolean DEFAULT false NOT NULL,
    po_number text,
    netsuite_json text,
    sent_to_netsuite boolean DEFAULT false NOT NULL
);


--
-- Name: item_prices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_prices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    price numeric NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    created_by text
);


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    netsuite_id text,
    name text NOT NULL,
    price numeric,
    is_livery_package boolean DEFAULT false NOT NULL,
    unit_factor numeric,
    average_cost numeric,
    is_inactive boolean DEFAULT false NOT NULL,
    last_purchase_price numeric
);


--
-- Name: livery_agreements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.livery_agreements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reference_number text NOT NULL,
    customer_id uuid NOT NULL,
    box_id uuid NOT NULL,
    item_id uuid NOT NULL,
    start_date text NOT NULL,
    end_date text,
    type text DEFAULT 'permanent'::text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    notes text,
    checkout_reason text,
    monthly_amount numeric,
    agreement_category text DEFAULT 'with_horse'::text NOT NULL
);


--
-- Name: monthly_billing_approvals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.monthly_billing_approvals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    billing_month text NOT NULL,
    step text NOT NULL,
    user_id uuid NOT NULL,
    approved boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session (
    sid character varying NOT NULL,
    sess json NOT NULL,
    expire timestamp(6) without time zone NOT NULL
);


--
-- Name: stables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stables (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    netsuite_id text
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    username text NOT NULL,
    password text NOT NULL,
    role text DEFAULT 'LIVERY_ADMIN'::text NOT NULL,
    sso_id text
);


--
-- Name: replit_database_migrations_v1 id; Type: DEFAULT; Schema: _system; Owner: -
--

ALTER TABLE ONLY _system.replit_database_migrations_v1 ALTER COLUMN id SET DEFAULT nextval('_system.replit_database_migrations_v1_id_seq'::regclass);


--
-- Data for Name: replit_database_migrations_v1; Type: TABLE DATA; Schema: _system; Owner: -
--

COPY _system.replit_database_migrations_v1 (id, build_id, deployment_id, statement_count, applied_at) FROM stdin;
1       bff36270-39b5-46e9-8300-250cd730bf92    70ada304-c814-40c3-bc4b-b836654e8103    4       2026-02-26 05:55:23.107682+00
2       89693640-9ab5-41b0-bf95-156dee0102c0    70ada304-c814-40c3-bc4b-b836654e8103    22      2026-03-05 10:21:00.686847+00
3       936b7b87-3663-45f2-9b1a-161f12313ea4    70ada304-c814-40c3-bc4b-b836654e8103    11      2026-03-29 19:39:16.016225+00
4       dd57ae31-7c68-4e85-a1c8-21de17597317    70ada304-c814-40c3-bc4b-b836654e8103    9       2026-04-10 12:47:17.181028+00
5       e6046c21-f85c-48a2-9f28-ac84b0d04c88    70ada304-c814-40c3-bc4b-b836654e8103    24      2026-04-14 10:41:03.89067+00
6       faf3727a-c8de-4a1d-a72f-b8c859e53589    70ada304-c814-40c3-bc4b-b836654e8103    7       2026-04-21 07:03:06.897177+00
7       71eee9ce-fd85-4924-9db2-710d46c91be5    70ada304-c814-40c3-bc4b-b836654e8103    1       2026-04-29 12:44:36.219122+00
8       75cf3b6f-0910-4a14-a12d-3d9f5797101f    70ada304-c814-40c3-bc4b-b836654e8103    5       2026-05-12 09:19:09.377002+00
9       452a9b38-c5a7-48c1-ba6a-6993799da951    70ada304-c814-40c3-bc4b-b836654e8103    6       2026-05-14 06:56:14.680639+00
\.


--
-- Data for Name: agreement_documents; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.agreement_documents (id, agreement_id, filename, file_data, uploaded_at) FROM stdin;
\.


--
-- Data for Name: app_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_settings (key, value) FROM stdin;
n8n_webhook_url https://n8n.srv1275904.hstgr.cloud/webhook-test/cdc3c7f4-ef99-4acd-9357-5f1346a16ec2
last_po_number  2026003012
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, user_id, username, action, entity_type, entity_id, details, created_at) FROM stdin;
77fbb2f3-7cc1-4c44-8905-3624f18d07ad    853acd7c-4759-4213-ace1-b7da16385a52    admin   update_setting  setting livery_packages Updated livery packages 2026-03-06 06:45:12.356806
17c3a8b6-f6ae-42a4-a9f8-bec66f83319c    853acd7c-4759-4213-ace1-b7da16385a52    admin   update_setting  setting livery_packages Updated livery packages 2026-03-06 06:45:18.972823
1765811e-4b8e-481c-98f4-b7e9cc3f04f8    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       a471ea9e-f497-478c-ae88-8d8fc653969f    Created agreement: LA-2026-1933 2026-03-06 06:47:11.306935
98b281ef-ff9e-462a-8ba0-164e4d1f726e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       85aa4929-050b-41c0-8e0f-e0d370de4636    Created agreement: LA-2026-2705 2026-03-06 07:00:42.152052
9d956368-28e4-481b-8297-fcd719f73271    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 18376310-af69-4299-b407-45b2207bddf3    \N      2026-03-06 07:04:08.425359
a4bafad0-4b0b-4859-9e57-3eea0d72c93b    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 21c291bf-07a1-4252-8eee-810b6ecff0f0    \N      2026-03-06 07:04:32.700569
b90a5942-ac42-43c1-9abd-f9228aa0334e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 0e8d9b41-6838-4837-bc06-83feb54fa3d2    \N      2026-03-06 07:12:14.421252
98a0accd-deb8-4d9d-9dcc-7b70c185910f    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 1b265dbd-eca9-4c2f-8a69-f88f4e551ec4    \N      2026-03-06 07:13:19.524636
e61c13ed-14f9-44fd-af46-7f42c7b72a70    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element d22b1bb8-70d6-459a-8fab-5bb02861b220    \N      2026-03-06 07:13:44.395878
08f3fae8-4b91-4595-a8c2-51596a750ec9    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 3ae7017a-58f0-4181-b5d1-8cfb320ae036    \N      2026-03-06 07:20:05.325741
5f7db1ec-b747-4394-98b1-2f29acba79c7    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice 46ed6d8b-7152-47d0-aca2-72f336ec6139    Created invoice for billing month 2026-01       2026-03-06 07:21:20.602852
55eaa3e7-15d6-4543-9dc7-7fb19c943fcd    853acd7c-4759-4213-ace1-b7da16385a52    admin   update_setting  setting n8n_webhook_url Updated N8N webhook URL 2026-03-06 07:24:53.712655
65764206-e406-4e14-8bd4-8d04ba4a791f    853acd7c-4759-4213-ace1-b7da16385a52    admin   update_setting  setting n8n_webhook_url Updated N8N webhook URL 2026-03-06 07:31:38.349361
aab46f7f-808c-48b7-8238-e19074d7d5d4    853acd7c-4759-4213-ace1-b7da16385a52    admin   update_setting  setting n8n_webhook_url Updated N8N webhook URL 2026-03-06 07:31:42.967825
b911a0a9-d532-4f36-b437-1d8102c1fe26    853acd7c-4759-4213-ace1-b7da16385a52    admin   update_setting  setting n8n_webhook_url Updated N8N webhook URL 2026-03-06 07:32:33.275597
503aad06-5585-446d-be9e-516968be07c0    853acd7c-4759-4213-ace1-b7da16385a52    admin   update_setting  setting n8n_webhook_url Updated N8N webhook URL 2026-03-09 05:34:30.700951
9194e8fa-8f63-444b-9a4c-deb8224bb36a    de0adb89-60c5-4188-871d-0a14bb226223    systemadmin     sso_login       user    de0adb89-60c5-4188-871d-0a14bb226223    SSO login via Unified Portal    2026-03-11 09:19:39.284372
85a8c5d7-6f7a-41d0-a372-29426b368490    de0adb89-60c5-4188-871d-0a14bb226223    systemadmin     sso_login       user    de0adb89-60c5-4188-871d-0a14bb226223    SSO login via Unified Portal    2026-03-11 09:20:27.917193
15697513-5119-4cbc-b1c5-2ee0e5e8e6f9    de0adb89-60c5-4188-871d-0a14bb226223    systemadmin     sso_login       user    de0adb89-60c5-4188-871d-0a14bb226223    SSO login via Unified Portal    2026-03-11 09:20:39.799461
425d5320-c560-4440-a1f7-38fa4bd1b850    de0adb89-60c5-4188-871d-0a14bb226223    systemadmin     sso_login       user    de0adb89-60c5-4188-871d-0a14bb226223    SSO login via Unified Portal    2026-03-11 09:21:12.716722
8dbad7ce-e9e4-426e-9f21-f3c8341f5d02    de0adb89-60c5-4188-871d-0a14bb226223    systemadmin     sso_login       user    de0adb89-60c5-4188-871d-0a14bb226223    SSO login via Unified Portal    2026-03-11 10:08:56.598345
898090bd-cdde-444a-b6e3-94d7f50826e9    de0adb89-60c5-4188-871d-0a14bb226223    systemadmin     sso_login       user    de0adb89-60c5-4188-871d-0a14bb226223    SSO login via Unified Portal    2026-03-11 10:10:00.579319
d532ec02-a8c0-432e-b3a9-e2d45d9856be    853acd7c-4759-4213-ace1-b7da16385a52    admin   sso_login       user    853acd7c-4759-4213-ace1-b7da16385a52    SSO login via Unified Portal    2026-03-12 05:46:23.020787
0f70d95c-0388-4a63-9f1d-af55013c2661    853acd7c-4759-4213-ace1-b7da16385a52    admin   sso_login       user    853acd7c-4759-4213-ace1-b7da16385a52    SSO login via Unified Portal    2026-03-12 06:21:29.429048
e4b43ad1-3db0-4650-acab-0554e7e33e96    853acd7c-4759-4213-ace1-b7da16385a52    admin   sso_login       user    853acd7c-4759-4213-ace1-b7da16385a52    SSO login via Unified Portal    2026-03-12 08:21:00.580146
d2415892-c216-4b32-b60e-a8d64eae7fd0    853acd7c-4759-4213-ace1-b7da16385a52    admin   sso_login       user    853acd7c-4759-4213-ace1-b7da16385a52    SSO login via Unified Portal    2026-03-12 09:01:20.661042
14bd97d9-7a26-4e9c-8294-851dff9626f6    853acd7c-4759-4213-ace1-b7da16385a52    admin   sso_login       user    853acd7c-4759-4213-ace1-b7da16385a52    SSO login via Unified Portal    2026-03-12 09:22:32.261545
6b857b55-318e-4ab5-bdcd-e405a392198e    853acd7c-4759-4213-ace1-b7da16385a52    admin   sso_login       user    853acd7c-4759-4213-ace1-b7da16385a52    SSO login via Unified Portal    2026-03-16 08:01:46.22072
081459db-64e7-475e-ba0a-072b2a5ec590    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       d6a81479-ac7f-4e68-b14c-dac839e25db7    Created agreement: LA-2026-6390 2026-03-17 06:48:26.186068
ec69d743-1534-45d1-a69a-3dcfc9c99035    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element e1b1de74-42e1-469a-a737-9542da1953f6    \N      2026-03-17 06:55:05.448048
e3fe91ff-f1a5-410c-b630-c8e9dad4a412    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 519451bf-f1f1-459a-9223-4df7dafd67d6    \N      2026-03-17 06:55:41.531169
34bbe893-c136-44d3-be12-ba077c77461c    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice c290c8f3-20a4-4af1-bfbd-462d22ee0c06    Created invoice for billing month 2026-01       2026-03-17 06:57:33.43787
8f0c4b67-f453-4cce-8c66-815034835b99    853acd7c-4759-4213-ace1-b7da16385a52    admin   delete_invoice  invoice 46ed6d8b-7152-47d0-aca2-72f336ec6139    \N      2026-03-17 06:57:44.098153
e305e97e-1b9f-4026-a353-097a17d8c6db    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 5ebc2a6c-62ce-4cbd-b19c-d7b2721f41e8    \N      2026-03-17 07:03:05.769285
e6bae772-e622-4d39-bf97-de47734ee419    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 4c94bef6-3849-4b43-9d0b-b579a9153f8d    \N      2026-03-17 07:06:09.138677
756a91f1-b0fb-41f5-8ebf-07d2011e5f1e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 3edc3393-f19d-4045-9a62-ada475b80246    \N      2026-03-17 07:06:34.586104
69062138-2e22-4458-8f58-add4573c0e30    853acd7c-4759-4213-ace1-b7da16385a52    admin   delete_billing_element  billing_element 4c94bef6-3849-4b43-9d0b-b579a9153f8d    \N      2026-03-17 07:08:31.83173
9109499a-50c5-4712-bef0-8ecaad409f3c    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element cedef388-1fae-44a0-a267-2144d293a92c    \N      2026-03-17 07:09:00.844492
17109318-7396-4398-9759-49510e660134    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice 2d99d6a3-6cdd-4a8d-a18e-6609c8bc32da    Created invoice for billing month 2026-02       2026-03-17 07:09:19.798355
45dd9a6b-739a-428c-91f5-b033280166b9    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       38d889e7-fbfc-4ab3-b82e-db6936fdb578    Created agreement: LA-2026-1726 2026-03-17 07:59:21.715505
7780490b-0345-4887-bfcb-844174e0edf2    853acd7c-4759-4213-ace1-b7da16385a52    admin   sso_login       user    853acd7c-4759-4213-ace1-b7da16385a52    SSO login via Unified Portal    2026-03-17 08:12:35.355011
81aedfc1-5a1c-46dd-ad0a-2d3a2fce2009    ec163552-70e2-4967-a6f3-3666c96befd5    Zeid    sso_login       user    ec163552-70e2-4967-a6f3-3666c96befd5    SSO login via Unified Portal    2026-03-17 08:15:34.168004
c1f154d4-bbeb-492e-8b27-9e7580402528    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 75238c8e-8fd1-41cf-be7f-177a554433de    \N      2026-03-17 08:37:26.16655
25d349b5-689e-4982-8e1e-40d6a0797b9a    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice f2a4fa8e-855e-4ef3-8f68-380dabd6173c    Created invoice for billing month 2026-03       2026-03-17 08:37:52.452959
4ff41db6-f477-436a-adc3-960b16e2b003    ec163552-70e2-4967-a6f3-3666c96befd5    Zeid    sso_login       user    ec163552-70e2-4967-a6f3-3666c96befd5    SSO login via Unified Portal    2026-03-17 09:46:53.880243
fa57a98f-a18f-403e-bace-3a93eca12fd9    853acd7c-4759-4213-ace1-b7da16385a52    admin   sso_login       user    853acd7c-4759-4213-ace1-b7da16385a52    SSO login via Unified Portal    2026-03-18 05:23:11.415993
5d5a8460-5017-47fb-8c24-4a2702ddcdd1    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    Created user: varun.mohan@adec.ae       2026-03-18 05:23:45.857038
110ad9b1-3a90-478b-bc59-f9f7f3832f15    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_agreement        agreement       5f845497-ede9-44ce-b0b9-a7dc0218fb62    Created agreement: LA-2026-7777 2026-03-18 06:23:28.615296
38e5a866-1ff9-4a21-8afa-5a4498dbea24    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element c9f77741-d441-465e-8ee8-ef670c828aac    \N      2026-03-18 06:30:12.982631
93bb6998-bc46-43a5-9651-1df611e4b620    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element 6b25b258-36f8-43c8-871f-96adcac51ceb    \N      2026-03-18 06:31:20.626051
e294c0a3-a053-4ef8-b19c-f169a41d7a67    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     delete_billing_element  billing_element 6b25b258-36f8-43c8-871f-96adcac51ceb    \N      2026-03-18 06:34:23.332145
f178d872-4937-4438-9ca1-4722b73a23ed    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element 5f37c32f-92dc-4893-8bc9-791040ac133c    \N      2026-03-18 06:35:55.570423
9edca33b-9ac8-40eb-a77e-15ad6af3d505    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_invoice  invoice 16d2cda4-de73-4c49-8644-d04595d0a6f3    Created invoice for billing month 2026-01       2026-03-18 06:36:43.328389
732dfa40-f9db-40f2-87da-9bbda1bc7557    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     checkout_agreement      agreement       5f845497-ede9-44ce-b0b9-a7dc0218fb62    Checkout agreement, end date: 2026-03-15        2026-03-18 06:40:17.692252
730821db-b41d-4c1f-be71-7405f25612d8    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_agreement        agreement       77169eb3-e6cf-4eeb-b541-5f26ac2f9906    Created agreement: LA-2026-2316 2026-03-18 06:50:13.606396
2e5973ca-6388-4c3f-8917-41a1347a7952    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element 1a4e1c7d-ebd6-4b36-88d7-79387f66aa2b    \N      2026-03-18 06:51:35.967701
dadc2f85-e0c3-4879-b6e5-90c0fc29c634    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element eda991ed-534c-4db6-ad68-d5571d86a224    \N      2026-03-18 06:52:10.054933
7fd07223-adf6-47f3-a7a9-8fac9c60bfa6    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element cb960d00-aa8f-4d05-af2e-e3d1cf5944da    \N      2026-03-18 06:52:34.065078
81339860-d620-48f0-8c29-845daba089a4    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element 6c2bfb8c-5ba2-4b0a-9dc4-eb3e2eb12726    \N      2026-03-18 06:52:58.667246
08f2340b-fbff-45ae-8693-da76dd90f56b    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_invoice  invoice d6046f0d-667b-4198-9080-622975b2a1e3    Created invoice for billing month 2026-01       2026-03-18 06:53:25.514458
d8a31752-296c-43e6-801d-fff4157ece2d    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element 8498a150-180d-4dc1-b3c7-8757719a2742    \N      2026-03-18 06:58:40.039439
e593492b-bb3f-452c-aeba-5858278d61d9    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_invoice  invoice a5a4e8c7-76c6-4476-ad6e-ec9475e9038e    Created invoice for billing month 2026-03       2026-03-18 07:00:14.928634
13445438-3e8a-496c-af1d-d408b331c862    853acd7c-4759-4213-ace1-b7da16385a52    admin   sso_login       user    853acd7c-4759-4213-ace1-b7da16385a52    SSO login via Unified Portal    2026-03-24 08:18:57.649047
296050eb-3cce-496e-90d0-fb0ad94b879d    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       976428ba-6eaa-483c-b01d-1d0fb91f0955    Created agreement: LA-2026-5938 2026-03-30 06:16:56.933668
6ac08f71-2d97-4680-ab9e-247131c59592    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       e8e4adb3-7be3-435d-8d94-15c157586e38    Created agreement: LA-2026-7920 2026-03-30 06:17:38.881182
430fe374-bb28-4938-ac99-41ba19d5a9f8    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       78f872d8-f649-42a0-9bfa-e2170cfeabab    Created agreement: LA-2026-9735 2026-03-30 06:18:10.523963
de7884bd-8d5f-4a3e-8a65-f097a933c17e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       c697f17b-cdef-47e5-b0cb-9cd9ed1a3ba0    Created agreement: LA-2026-6641 2026-03-30 06:18:27.434472
36f87bf6-1c24-4a1b-8895-14fa3afcf38d    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       275d4902-18fc-408f-ba3b-1919ee02cb4c    Created agreement: LA-2026-3622 2026-03-30 06:19:04.425868
65202173-2966-44fb-80ae-b3b201189159    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       4291bb46-d0c8-4e02-b3bf-4e8e8fd688c1    Created agreement: LA-2026-4217 2026-03-30 06:19:24.997656
a4e2d1b8-24a6-45b2-a404-4d1c8cce8415    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       4f952c41-1621-4e7c-a528-e9ebef8515c4    Created agreement: LA-2026-2693 2026-03-30 06:19:43.486953
d3ca7268-5571-429b-800e-bbb58af767ce    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       8c90c419-24bd-4104-b2a2-72761f446676    Created agreement: LA-2026-4087 2026-03-30 06:20:14.884828
710c86c8-3f3c-40f4-8ad2-d03bb1060a75    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       56886b4c-61c2-4aa8-9f34-765efa27fcdf    Created agreement: LA-2026-3668 2026-03-30 06:22:44.464714
2d7c43b0-501a-463c-b8e4-2d3b5b34b411    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       e39c91ed-d36a-44e7-8c73-dbf93042ed7c    Created agreement: LA-2026-6420 2026-03-30 06:25:37.228886
50faca29-49a1-469a-b7f7-5a9295f2e3f4    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       79da59f7-d58a-4792-8285-f4b2903debb0    Created agreement: LA-2026-0835 2026-03-30 06:34:21.785309
0a68681a-d404-41c2-bf74-771dd523152c    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       963ccac2-3504-4977-8cb9-b8ae24be4ecb    Created agreement: LA-2026-7394 2026-03-30 06:34:58.360662
332587d0-56b7-4775-9ffe-cbc37f7a1db4    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       4b976b15-0ba5-487b-bbb6-6b83753c2e0a    Created agreement: LA-2026-9507 2026-03-30 06:36:20.519733
44c6bf3b-b069-499b-8e00-442e78c42a41    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element eab627f3-98a6-412b-b8bf-9d9cf17593d2    \N      2026-03-30 06:36:47.062315
c24b4409-859a-46eb-b09a-4cf04c3ff7fe    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice 77e667b2-7937-4c16-869b-31d5c688ca5b    Created invoice for billing month 2026-03       2026-03-30 06:36:56.985288
56a20710-81c6-443e-a5fa-8704b18f2a15    853acd7c-4759-4213-ace1-b7da16385a52    admin   send_for_validation     invoice 77e667b2-7937-4c16-869b-31d5c688ca5b    Invoice sent for VET validation 2026-03-30 06:37:04.193019
d9e2e934-401a-446b-96ed-7f7f35fdaaf0    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_invoice invoice 77e667b2-7937-4c16-869b-31d5c688ca5b    Approved at ADMIN_OVERRIDE, new status: STORES_VALIDATION       2026-03-30 06:37:07.551021
dce92fab-38bd-4a4d-8acf-7f913464d110    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_invoice invoice 77e667b2-7937-4c16-869b-31d5c688ca5b    Approved at ADMIN_OVERRIDE, new status: FINANCE_VALIDATION      2026-03-30 06:37:09.855323
5d2b90fb-d0ee-46c8-ad82-0d887be5f77e    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_invoice invoice 77e667b2-7937-4c16-869b-31d5c688ca5b    Approved at ADMIN_OVERRIDE, new status: APPROVED        2026-03-30 06:37:12.23546
b8c51226-60a5-4a84-b758-c472f9ded47c    853acd7c-4759-4213-ace1-b7da16385a52    admin   delete_billing_element  billing_element eab627f3-98a6-412b-b8bf-9d9cf17593d2    \N      2026-03-30 06:39:40.803338
a7f56827-b604-4553-87a0-134c255efd38    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice 5a1f1b46-b4b7-4057-a21e-73d6f0b221df    Created invoice for billing month 2026-03       2026-03-30 06:40:37.002908
73793efe-fa1f-4362-ab00-b5c5193bd0f8    853acd7c-4759-4213-ace1-b7da16385a52    admin   rollback_invoice        invoice 5a1f1b46-b4b7-4057-a21e-73d6f0b221df    \N      2026-03-30 06:41:36.456396
760bc6a9-b2a6-4f39-9982-2ca30518ace6    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element cc220bbe-afd6-4cfb-a934-c001dd0cb1ca    \N      2026-03-30 07:11:53.949309
9cadaab5-1d21-474c-ac0f-083bd00b2372    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 6d7b8f9f-1344-4dbd-a0bb-f3a0914a3170    \N      2026-03-30 07:12:21.289166
71fc4dfa-2b03-41af-9dba-09095432f045    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice 5ed610f3-a4c8-4b02-8966-dbfd730ddac5    Created invoice for billing month 2026-03       2026-03-30 07:13:07.714596
111d8620-b9e5-4788-a2f7-4a022edd7279    853acd7c-4759-4213-ace1-b7da16385a52    admin   send_for_validation     invoice 5ed610f3-a4c8-4b02-8966-dbfd730ddac5    Invoice sent for VET validation 2026-03-30 07:13:56.29901
e9e151d9-40ba-4c9c-985f-848086a58137    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_invoice invoice 5ed610f3-a4c8-4b02-8966-dbfd730ddac5    Approved at ADMIN_OVERRIDE, new status: STORES_VALIDATION       2026-03-30 07:14:18.183162
ccd02288-08f8-412c-946a-ddac976bbe73    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_invoice invoice 5ed610f3-a4c8-4b02-8966-dbfd730ddac5    Approved at ADMIN_OVERRIDE, new status: FINANCE_VALIDATION      2026-03-30 07:14:30.804395
b4e638e1-2f88-4f21-885f-3da4a801a913    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_invoice invoice 5ed610f3-a4c8-4b02-8966-dbfd730ddac5    Approved at ADMIN_OVERRIDE, new status: APPROVED        2026-03-30 07:14:34.266934
e0e8b35a-8196-4331-bb4f-5e3693de4124    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice 6943fc08-cd4d-45a8-9a52-95174c00eba7    Created invoice for billing month 2026-03       2026-03-30 07:17:06.271129
9d6f20fe-60f8-4920-844b-f63612a0db8e    853acd7c-4759-4213-ace1-b7da16385a52    admin   rollback_invoice        invoice 6943fc08-cd4d-45a8-9a52-95174c00eba7    \N      2026-03-30 07:17:17.396972
88ad8e1f-4938-4d0f-bd65-50459dd449a2    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice 72f21617-1192-4ccb-aaf4-fed3e7c9d6d2    Created invoice for billing month 2026-03       2026-03-30 07:17:31.844884
a6bcf5cd-c968-46ce-b386-327415758c28    853acd7c-4759-4213-ace1-b7da16385a52    admin   send_for_validation     invoice 72f21617-1192-4ccb-aaf4-fed3e7c9d6d2    Invoice sent for VET validation 2026-03-30 07:17:37.842882
40148661-96e4-433c-8499-e2057d63a571    853acd7c-4759-4213-ace1-b7da16385a52    admin   reject_invoice  invoice 72f21617-1192-4ccb-aaf4-fed3e7c9d6d2    Rejected at ADMIN_OVERRIDE: wrong item  2026-03-30 07:17:46.219922
b16f46e7-a637-4a58-966e-9677c3359dc2    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element aaea5ec0-fcdf-43bf-8f0b-5ac40a48af7c    \N      2026-03-30 07:21:12.191042
10f7cb03-5472-4fb9-b74b-2bb63f06dd4c    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice 2c7ef386-5eae-447e-8c32-9721d8b366fa    Created invoice for billing month 2026-03       2026-03-30 07:21:24.821183
722554ea-dde7-41ae-a898-8eb1ff428101    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       23c31f9e-99fc-41bb-8ad1-31c4142f36a8    Created agreement: LA-2026-5705 2026-03-30 07:22:56.519573
2d82fc18-e9e6-4eb9-b977-4036d7005950    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element fe456279-df7d-43a0-9fa7-736fba981366    \N      2026-03-30 07:23:29.970228
2eafd486-97df-4b86-8a74-04c23dbd3c86    853acd7c-4759-4213-ace1-b7da16385a52    admin   checkout_agreement      agreement       23c31f9e-99fc-41bb-8ad1-31c4142f36a8    Checkout agreement, end date: 2026-03-31        2026-03-30 07:24:42.254982
7befbfc3-c545-4b98-9ecc-b9878be6e7d0    853acd7c-4759-4213-ace1-b7da16385a52    admin   checkout_agreement      agreement       23c31f9e-99fc-41bb-8ad1-31c4142f36a8    Checkout agreement, end date: 2026-03-29        2026-03-30 07:25:02.090125
890c4921-ec2d-423c-a527-1fc90cd6f363    853acd7c-4759-4213-ace1-b7da16385a52    admin   checkout_agreement      agreement       4b976b15-0ba5-487b-bbb6-6b83753c2e0a    Checkout agreement, end date: 2026-03-20        2026-03-30 07:31:43.739098
4c0a5ca1-12f4-41aa-8de7-c0a8128eef37    853acd7c-4759-4213-ace1-b7da16385a52    admin   cancel_checkout agreement       23c31f9e-99fc-41bb-8ad1-31c4142f36a8    Cancelled checkout for agreement LA-2026-5705   2026-03-30 08:09:53.702258
55352c9e-0aec-499e-91f2-ab270c9f65d8    853acd7c-4759-4213-ace1-b7da16385a52    admin   cancel_checkout agreement       4b976b15-0ba5-487b-bbb6-6b83753c2e0a    Cancelled checkout for agreement LA-2026-9507   2026-03-30 08:09:55.980922
df6d147f-1930-4e54-955c-8a75a1f3d0be    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    932b73f2-51b9-42f9-805a-da2409661b9a    Created user: jassim.shanavas@adec.ae (role: FINANCE)   2026-03-30 08:20:34.397292
1fe11618-ace7-42bf-a423-6050cde582b4    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    3823058b-4ef5-4c22-913f-9cd149cbb6e0    Created user: orla.ohanlon@adec.ae (role: VETERINARY)   2026-03-30 08:21:00.170049
b14debbd-bda5-4432-8af9-74f014f47a24    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    ef15f912-26cd-4a82-b345-2e20f4706490    Created user: nixon.silveira@adec.ae (role: VETERINARY) 2026-03-30 08:21:24.313272
06414094-4ead-4a32-aaf3-d2a254b29e77    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    50714bb1-7f0e-4363-b470-1c7af22870d4    Created user: Muhammad.saad@adec.ae (role: STORES)      2026-03-30 08:21:50.079892
ea3ced44-b086-405e-ba29-bf9f697de519    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    Created user: andrea.villarin@adec.ae (role: LIVERY_ADMIN)      2026-03-30 08:22:15.579686
13a8c17b-b238-4151-b2b0-0e547a95806e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       e94133b4-ba36-4078-ab67-9e3c1ce0e3c7    Created agreement: LA-2026-1670 2026-04-06 07:09:21.096806
dda3ce85-c1c8-448c-b8a0-9a3a258210fa    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       c248c9d9-2483-44e1-9480-3a26da27f876    Created agreement: LA-2026-0712 2026-04-06 07:13:01.434504
b890bd32-5e98-4aac-ba8b-4818ca58e24d    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       11dcfe17-4df5-4c59-863a-f3b8fe6158af    Created agreement: LA-2026-8936 2026-04-06 07:14:19.186444
7294040f-2376-4a12-8b79-ea83b327482e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       dde5166e-43e3-48b8-ac0d-8b5d43f04031    Created agreement: LA-2026-6357 2026-04-06 07:15:25.943406
7ac48684-7834-4952-8524-1a3283347fa6    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       6252dd06-7948-44c3-8b76-8e1e01b62622    Created agreement: LA-2026-9130 2026-04-06 07:16:48.68135
cfa2006f-b15b-4d44-b7ee-b36e2a0afbab    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       f23d4cb8-8ec7-4549-8f86-d7547d5e176f    Created agreement: LA-2026-7433 2026-04-06 07:17:46.963426
ddf22631-6d19-4d1f-80b1-dfa686bf67e1    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       2c051d7f-c850-4255-9048-f017293c0a97    Created agreement: LA-2026-0242 2026-04-06 07:18:49.689218
566a6e63-9aed-4feb-9b03-0ef97caa1956    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       eab9ed85-8908-44b6-97c4-9c087807aa27    Created agreement: LA-2026-1455 2026-04-06 07:19:30.866874
17140d73-f097-4c0a-accd-dcd7d2000f5d    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       dd81c6d0-b66d-4ce9-82e9-d6e9ad835354    Created agreement: LA-2026-1005 2026-04-06 07:20:20.432476
eecd461a-5d0d-4858-8158-c3076b8fe2d6    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       e74a728c-e594-46fa-a686-c08b87fd9f9e    Created agreement: LA-2026-2789 2026-04-06 07:21:12.188496
c21845d1-262b-4a86-af27-41d0c936d6a2    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       eb1f2054-37c1-4c9a-8b27-7421ae3dd6cb    Created agreement: LA-2026-2949 2026-04-06 07:25:22.348882
9032a758-c921-454e-8a1e-02ec043123c8    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       205233e9-491a-4038-b395-6814c7b98c07    Created agreement: LA-2026-1290 2026-04-06 07:26:40.702055
bb408a06-d86e-47a7-9301-d4f1d2d34350    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       047c8299-8c3c-4f81-9b3b-3946c6f72c6b    Created agreement: LA-2026-2572 2026-04-06 07:28:13.267494
0bc9283a-520a-4b4c-9f13-ca235e573a0e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       a621e7fd-ea3c-4b02-836b-2146fff023ed    Created agreement: LA-2026-8232 2026-04-06 07:52:38.754284
92f010a9-dd27-4f27-b32f-0f8ae37dc5f5    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       1a8dc5f7-44c2-4c71-b573-0289a6792c3f    Created agreement: LA-2026-5421 2026-04-06 07:54:45.648976
a435be52-f441-4516-8b89-f0a2a18f19ce    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       36e479ca-f1d5-41d1-be08-f0d995046e98    Created agreement: LA-2026-7522 2026-04-06 08:00:07.782082
8eb68e6e-dbaf-47d4-a4a5-3b8b3dca7207    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       6d788b08-240a-4106-8d27-98cfb0ba4640    Created agreement: LA-2026-9442 2026-04-06 08:01:19.005281
d35aed92-1835-4fb3-9567-f6ca95014483    0bbe2f72-b2c8-476c-b586-579282fbff4a    Radha   sso_login       user    0bbe2f72-b2c8-476c-b586-579282fbff4a    SSO login via Unified Portal    2026-04-06 08:12:04.709599
6967ca99-6450-44cb-bd36-9a2d5fe86535    853acd7c-4759-4213-ace1-b7da16385a52    admin   change_item_price       item    834900c6-97ec-4aa8-a3b9-eee40c4eca15    Price changed to 200 for item ClinicSRV -Ultrasound Reproduction        2026-04-06 10:58:04.437992
e66e254e-e100-4508-b9b8-9f2c74ad2a5a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    f988eb97-f452-4c9a-bc84-bf71cd195ff3    Price changed to 1250 for item ClinicSRV -Pre-Purchase Exam - 5 Stage   2026-04-06 11:17:06.567624
375c469c-8d3f-4262-939b-66885e756c47    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2e4cc5fd-145c-4ca1-bd19-04235644fa51    \N      2026-04-06 11:17:27.238181
cfda6106-766d-40c1-900f-49bf62429ee7    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    6b109571-1a7b-4d1f-a9a5-fb85fb82e39b    Price changed to 2500 for item ClinicSRV -PPE Xray Package 3: Front Feet, Hocks, Fetlocks, Stifles, DSPs        2026-04-06 11:19:03.205337
1f2cb846-fa74-4802-8a93-d300311048d4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 8145629d-cc14-4f3a-9c91-27c1a5fa489e    \N      2026-04-06 11:19:33.108426
65b46766-e43f-4d40-8694-41db5d92f782    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    e6149f99-35ea-483c-a8a0-01dc1128ffc1    Price changed to 100 for item ClinicSRV -Lab - Sample Collection        2026-04-06 11:20:05.946046
81cca3aa-4420-478a-915c-29d4a70ad265    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element af41fb01-d03d-422c-929f-e8edc122e799    \N      2026-04-06 11:20:17.639096
8468cf42-2f19-4ed1-80c5-ab9e04284de9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 67a55c45-486b-43fc-98b0-dda498a5625d    \N      2026-04-06 11:20:42.386245
54fa0c85-a01b-421e-b37c-940fb0391a73    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element ba148110-f665-4ac0-b118-7de8be7c0a08    \N      2026-04-06 11:22:45.627638
cfb8f6eb-d4a3-4a1f-bb79-efd928dba37d    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 2e4cc5fd-145c-4ca1-bd19-04235644fa51    \N      2026-04-06 11:24:59.876226
e5bbac1e-501a-4277-8e70-8a8777351ded    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 8145629d-cc14-4f3a-9c91-27c1a5fa489e    \N      2026-04-06 11:25:02.475343
b275e27d-1777-48b7-8bd6-8bea1bde7d30    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element af41fb01-d03d-422c-929f-e8edc122e799    \N      2026-04-06 11:25:03.916146
dbc21bac-7044-469d-9501-971923e747a2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 67a55c45-486b-43fc-98b0-dda498a5625d    \N      2026-04-06 11:25:05.699132
f4b38e50-f117-4e54-b1a5-6947bf9db96b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element ba148110-f665-4ac0-b118-7de8be7c0a08    \N      2026-04-06 11:25:07.55746
78537716-df1e-47e5-8bee-40b4ee6c7a36    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element 49512389-a114-4f36-9314-c342c5a046a2    \N      2026-04-07 10:34:01.020508
b0415708-812d-44d3-82f5-02cb6e5cdf25    853acd7c-4759-4213-ace1-b7da16385a52    admin   delete_billing_element  billing_element 49512389-a114-4f36-9314-c342c5a046a2    \N      2026-04-07 10:44:00.492496
75bf7bca-6f74-486b-ba9f-65d540fb074a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 288b1f6d-c525-4ba5-8c7b-aa4bc00ce925    \N      2026-04-09 06:55:33.479868
318b2040-71c8-4d91-bb64-ce1b74690e2d    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element e9c37ea6-c204-45df-90ce-9ab91d706e99    \N      2026-04-09 06:56:15.068198
11004747-9183-4ae0-a0b1-05813f5dfb1c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 7a5364c5-5a97-4469-8a3d-6d8d6ea75166    \N      2026-04-09 06:57:33.566094
4d4a182d-75da-4c15-abe3-305732479346    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2a89e918-5a5f-400c-9708-734908c54348    \N      2026-04-09 06:58:06.619257
418f2184-cca3-455e-9e06-5d612fa3cf6b    853acd7c-4759-4213-ace1-b7da16385a52    admin   sso_login       user    853acd7c-4759-4213-ace1-b7da16385a52    SSO login via Unified Portal    2026-04-09 11:37:57.059054
b5f3b3f9-b520-4d55-ab7b-cd5995c4f2ee    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       bee8af2a-5fc0-4624-a5ab-7b9eb45f8cfa    Created agreement: LA-2026-9220 2026-04-10 13:28:38.6704
7a201dfc-14e3-4fe9-9e0e-cb39d6a9c7cf    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       aa520b85-1ffa-4ee8-9615-078a6ff06db0    Created agreement: LA-2026-3720 2026-04-10 13:39:53.150351
7abecd50-e19c-4b70-8b51-83551fdddc22    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       b75ea39e-a8dc-49ee-8464-522ec2628f3e    Created agreement: LA-2026-2794 2026-04-10 13:51:42.231077
fd08eeb6-e488-4814-97d6-a68da56010fa    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       c16b9e28-f638-4839-ab11-6d1d257e73f9    Created agreement: LA-2026-0128 2026-04-10 13:56:29.581005
0aca1026-5fb7-4be6-9944-4255ee910171    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       0bef9c96-2792-441d-80a2-6b292d33210a    Created agreement: LA-2026-6218 2026-04-10 14:01:05.691678
0891ba1d-37cd-4a0c-870d-252eae3edc30    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       2ac7c619-d5f7-4503-b675-8605902700fe    Created agreement: LA-2026-7662 2026-04-10 14:02:56.724279
b6d3466a-4e53-420c-8be3-99cff260bff6    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       bc66e8b5-2972-4793-bf92-e3e45412faff    Created agreement: LA-2026-0104 2026-04-10 14:05:09.527746
c62c702d-efaa-443e-a84c-b901493cb92a    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       e3e80874-51f0-4279-8602-bd1abb3b5d22    Created agreement: LA-2026-1817 2026-04-10 14:11:01.258309
36d62940-a1e6-41ac-bb74-a4da7c65fad7    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       ec654c68-bad5-4830-902a-1dda90e66dda    Created agreement: LA-2026-0683 2026-04-10 14:12:50.108998
f396a10e-6801-4c7b-a7c0-d80300401ce8    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       f7967797-3262-41b4-a1fd-0ef55091d57f    Created agreement: LA-2026-0036 2026-04-10 14:15:59.484066
aa2008d3-a2fc-4b8f-9698-5ce8ee920d82    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       a39fbacb-42ae-48da-920f-4e6122c2dd5a    Created agreement: LA-2026-3105 2026-04-10 14:19:42.522758
44e4b74a-1051-4890-a2b8-3c9138a86f75    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       72fba684-3a74-4a4a-9b6c-c21f69482130    Created agreement: LA-2026-4780 2026-04-10 14:21:34.19537
60597a64-636b-4990-b474-d1b98c5d11ab    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       efd51bad-03ef-4265-91d4-5a6746f23d93    Created agreement: LA-2026-8018 2026-04-10 14:23:57.072971
61737bfb-7d0b-4b9a-b611-14850cacba82    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       eab8ab6e-06ef-4a46-87bb-de9cf0611e79    Created agreement: LA-2026-6647 2026-04-10 14:25:06.066348
b4295319-1aca-40a0-9015-f0e06183bfd2    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       8fbea8dd-a8be-42db-9824-36eaa36b598f    Created agreement: LA-2026-9197 2026-04-10 14:25:58.253327
8718e3b9-1738-45a8-a82a-631043fc351b    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       17b270a3-9b9d-4336-a47d-41a3e0827675    Created agreement: LA-2026-6085 2026-04-10 14:26:45.500972
a1b89eb2-20e7-4565-b85b-88324a1cfc6f    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       6a028016-fbde-47c2-a596-73e2aef564f6    Created agreement: LA-2026-5903 2026-04-10 14:29:04.949796
4be011de-9dd2-4a2e-8ebd-51016116b7bf    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       a6557202-19a3-4645-83b0-9d63395ee786    Created agreement: LA-2026-6651 2026-04-10 14:30:26.107841
3d154635-5267-49bf-95df-abb62e9837bf    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       ed3408de-2e7e-47ce-95fc-f6f65df2456b    Created agreement: LA-2026-8467 2026-04-10 14:37:37.909424
d5642734-58ee-4ac6-9252-c56c6b2766f1    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       4c73c706-6945-4110-8f8c-c146a54bd964    Created agreement: LA-2026-1844 2026-04-10 14:38:41.258097
37d9c7ec-700f-4720-b8a5-101650cbff3d    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       5acca11a-b92a-4177-86af-ae9f9aaf9915    Created agreement: LA-2026-5109 2026-04-10 14:39:44.149425
373cc22d-4ebc-43e2-a27f-07a38858ca87    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       af10d581-1db5-4b16-bac8-e1b28c6ec705    Created agreement: LA-2026-9002 2026-04-10 14:40:38.421441
6a100406-bd40-48fb-afd0-0a966163e7ae    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       9f97e0fe-86ab-4a73-99f2-f16d7e7a34e9    Created agreement: LA-2026-5384 2026-04-10 14:42:34.802362
aa324d55-d4bd-467d-9599-4961ed46f0b0    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       2bcd2cdb-3340-4a88-80a5-25973253933b    Created agreement: LA-2026-4973 2026-04-10 14:44:04.397191
bf7ae397-0d38-44cc-bdfa-8a512653b470    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       a78ae6cb-eca2-4902-ad6b-dbdeb506d4e9    Created agreement: LA-2026-0398 2026-04-10 14:47:09.797455
43e1c479-b672-4b46-b16a-750c50670250    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       470b1df7-928d-4c53-bded-d00cc7db60fe    Created agreement: LA-2026-6754 2026-04-10 14:51:15.794084
0ce78f39-bc2a-474e-98be-e5f81d6b7b9a    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       bd4d6227-5901-4ed9-8f36-54c3c149c7ae    Created agreement: LA-2026-9953 2026-04-12 07:34:30.166813
d18e1bff-8c70-4d93-a3c5-32444dd2ff57    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       10dcb153-7fea-4383-ab58-f1c112af5a70    Created agreement: LA-2026-8666 2026-04-12 07:36:59.272991
c729bf09-a81f-472e-b12c-b6bf5a161ed4    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       e29364a3-3422-4849-9b8a-9bc621cd7a37    Created agreement: LA-2026-4893 2026-04-12 07:38:15.369109
6751013c-6c70-4b9a-a028-4b428ea2b3b4    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       a301d561-15ea-4ee8-97b3-7d574e7938a8    Created agreement: LA-2026-3520 2026-04-12 07:40:04.229265
312ee665-86bf-4919-bb8d-40dfbcd6fe9a    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       828f4d13-1d9c-4155-8bd0-fb2178999f79    Created agreement: LA-2026-7690 2026-04-12 07:41:47.894386
5684c530-cd2f-4610-8688-ead61b7f7e3e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       2c9cff1d-7b6b-4a53-9dc0-081b2446df3f    Created agreement: LA-2026-8312 2026-04-12 07:44:28.45328
366d2add-bab7-47ae-8266-584a66d7c24c    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       85247fa6-758f-4ceb-a245-83f03be36b85    Created agreement: LA-2026-4076 2026-04-12 12:43:04.120678
649309e3-27a5-41a2-90ab-02307e8218ce    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       e2d47b81-6601-4db4-bea4-364757be60c7    Created agreement: LA-2026-7647 2026-04-12 12:50:57.674831
e875fd30-cc76-4ce6-af75-ef787a2b4980    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       84dcd7f8-dbf2-43af-992d-970c2a8ba64b    Created agreement: LA-2026-3680 2026-04-12 12:59:03.806993
ab3b9c2f-776d-4bae-9038-4deed4b4b4d8    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       73fe9898-b3a5-4a88-b687-a3bf947be318    Created agreement: LA-2026-6606 2026-04-12 13:01:36.679512
a7781554-9067-4cea-9905-7c88e059d607    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       e143a973-3a8c-4626-85ae-8f55f36b75b1    Created agreement: LA-2026-5860 2026-04-12 13:04:05.833395
d013949c-ecdc-4cbf-8a76-53d7e3bcba91    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       c5493602-a71f-4766-a45d-c2d33bdfcdf0    Created agreement: LA-2026-1252 2026-04-12 13:07:31.216976
87213b9b-d69d-4966-b6c5-256db2ddb1aa    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       44ea6aca-3b79-4b70-b050-2c11e929a942    Created agreement: LA-2026-5328 2026-04-12 13:08:35.326876
5f8edd82-ceae-4ea4-9c35-f7c22b4683d4    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       94663740-d04f-443a-8309-17780d884077    Created agreement: LA-2026-1704 2026-04-12 13:13:41.720477
a16ded0c-2349-47bb-9797-b8b55e068656    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       3ecae716-2aa4-4f29-bd63-759f080bb711    Created agreement: LA-2026-1388 2026-04-12 13:16:31.376897
c14d7d23-c4b4-4d68-964b-d779b689222c    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       f80fb283-a9bd-4032-b94d-2cc7604552fb    Created agreement: LA-2026-4718 2026-04-12 13:18:34.689624
c8f20b2f-0258-4014-8ca4-ad1c6ec34981    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       bef56d65-f228-497a-af24-0bbfac64703b    Created agreement: LA-2026-8585 2026-04-12 13:20:28.553315
5544de8b-6747-4885-80c0-31add777c0d7    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       9b1d42b7-9ac4-4d7b-aa6a-e5a9e3421dc9    Created agreement: LA-2026-2457 2026-04-12 13:28:42.326523
dcd46681-6ae2-4b4b-8e23-49eea517a65c    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       55cdf57d-db44-436d-a52f-2ea5948ad0f1    Created agreement: LA-2026-1735 2026-04-12 13:29:41.582282
fee62446-59ef-4a52-bd31-9b9f837150f6    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       5da92382-674f-4dca-8d50-ecd03859ab13    Created agreement: LA-2026-9298 2026-04-12 13:31:29.133067
4ae6602a-20db-482a-9cc2-b61fedf89075    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       d0ff2a0f-c59b-4bfd-9f75-b28ca81b75bf    Created agreement: LA-2026-8953 2026-04-12 13:32:29.118825
a4004fb9-5dd4-4f75-a203-e7c3cdc01dbb    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       d46e6d55-a2ea-4c35-b75b-5d1d88bbdbb3    Created agreement: LA-2026-7409 2026-04-12 13:37:37.267583
23ac8eb5-edd6-4a44-a330-434e15197d33    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       91343df2-d3fe-4165-a5e4-0729f87b6324    Created agreement: LA-2026-5853 2026-04-12 13:40:45.737102
6d98cd69-e825-4541-b536-30d75387be6b    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       8247d7cc-052e-4622-86d5-d24c23a24c0c    Created agreement: LA-2026-5456 2026-04-12 13:41:55.546556
bf4dabbc-499e-4bc5-899f-38ce5ed9bc3c    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       67f16924-16a3-45ef-95db-b50e501666df    Created agreement: LA-2026-8874 2026-04-12 13:45:58.345077
ab07f8a1-8d69-4d33-9b8e-e73df476be6e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       e06ccadb-ed0a-4c88-acdf-5d2d5691ef6b    Created agreement: LA-2026-3461 2026-04-12 13:47:03.322843
b43b2b53-2e7b-48dc-a357-018ff492a6d9    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       971f6b22-4336-41e8-80d4-f38943f36f2c    Created agreement: LA-2026-4646 2026-04-12 13:48:54.120175
338c21e7-54b9-4b7e-970e-b12fbbee6f33    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       ed861515-3b31-491a-96b4-49e913e32add    Created agreement: LA-2026-3559 2026-04-12 13:50:43.741695
3eb790df-0899-43a1-967b-da54923f171f    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       577d1b72-adb1-4bb2-bfa8-52b4568bbfab    Created agreement: LA-2026-8381 2026-04-12 15:01:58.300962
191d33cf-17d1-4f12-8f21-22c802878bf3    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       da821b07-eda4-4b44-a037-b4492435ab51    Created agreement: LA-2026-8185 2026-04-12 15:03:27.987784
b983dbff-0684-4a23-8d28-638637106f4c    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       41742b12-84bb-4cb5-be32-9d2d6cc319f5    Created agreement: LA-2026-1874 2026-04-12 15:04:31.376322
f965f3f9-8dde-4dd8-9663-60a3939b66c0    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       c5d40c6c-a163-4725-9d28-ea3912782fd6    Created agreement: LA-2026-4312 2026-04-12 15:05:24.175414
92c18f22-72b3-411b-9bb6-9f364f33f5ad    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       fd6ca2a2-edd8-4717-999e-00d94d14092e    Created agreement: LA-2026-2086 2026-04-12 15:07:32.045124
48ba6b48-4251-4778-832c-eef147a98f6c    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       1696abad-761a-4397-a148-408e36a6c286    Created agreement: LA-2026-1681 2026-04-12 15:09:02.169152
80457382-4241-4d0b-80a7-9e6b48ae713a    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       bdcadd5f-3168-4767-ad61-8cf94dcf97a2    Created agreement: LA-2026-1073 2026-04-12 15:10:20.62913
11156938-0db5-4acb-b73e-9516d5f57864    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       cb3ef667-f440-4d62-bead-3ef77e6e74ae    Created agreement: LA-2026-6209 2026-04-12 15:11:16.018028
41f01d85-5e91-45a5-9c6a-8aaa26950101    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       e20e6baf-10b6-403b-8695-189898e5d124    Created agreement: LA-2026-2278 2026-04-12 15:12:21.719075
c9432a27-3673-491a-8e5e-d8bfe36fa121    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       3bd58602-8159-4f6a-b65e-4119e546db1d    Created agreement: LA-2026-4620 2026-04-12 15:13:34.425531
abd1db77-f7b7-4777-8fd4-bd869ca8862b    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       be843786-6f31-4e06-a062-afb82ad39291    Created agreement: LA-2026-2825 2026-04-12 15:14:42.62385
0df916cd-e483-42fd-bf95-be564f2866f8    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       13562d64-eb5d-4764-bbad-bf3afa332fc9    Created agreement: LA-2026-7940 2026-04-12 15:16:07.821056
27c318d3-3453-43c7-bd3b-a02255c6e14a    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       4ff9ff90-c128-4e3d-a982-3b5f34657acf    Created agreement: LA-2026-2348 2026-04-12 15:17:22.246112
96c7070d-2bc9-48e0-9871-018f53e4c0c8    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       efea762f-d6d7-422b-91a1-01e4e94feb4a    Created agreement: LA-2026-8568 2026-04-12 15:18:28.45426
ef02ba67-db4c-4b15-bdf2-93413f31f9fc    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       62fdb2a4-1bf5-495b-85f0-f442d530e98f    Created agreement: LA-2026-6781 2026-04-12 15:19:26.26019
a912fb73-49e0-4bee-9fa2-ce723b5a4d0a    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       ee062a5e-08e2-4503-bc70-434f80165f8c    Created agreement: LA-2026-1649 2026-04-12 15:20:11.065636
0f323155-b56b-4bef-821b-20cbaf081b6b    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       31fadc25-ff42-45ce-9178-a2cb454128bd    Created agreement: LA-2026-1979 2026-04-12 15:21:01.473928
f834d875-146c-4730-9e68-0562deaee3cd    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       34331cf6-b646-46b1-964a-9e4a2c159b72    Created agreement: LA-2026-5977 2026-04-12 15:21:55.489065
53a0d552-8a29-4ed2-a61c-2b2bf220589a    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       c3602a8b-aa66-4339-aa18-a346bdf3e6e5    Created agreement: LA-2026-3867 2026-04-12 15:24:03.290595
76c3c5d5-6f5a-4f00-bf1e-078a00400334    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       bb6d2c20-bce0-4f5a-9c52-2ae89f629072    Created agreement: LA-2026-2271 2026-04-12 15:25:11.712697
1d6f04be-6af0-4d8d-8044-7a83e2f7007d    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       bfe80498-2b3f-43bb-9cee-2ca25e65c755    Created agreement: LA-2026-3900 2026-04-12 15:26:03.809021
160a8293-f48f-47e1-bb15-ec8435f55cc0    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       7a38b68d-9dfd-4ebd-ad20-c09127aaab0a    Created agreement: LA-2026-9273 2026-04-12 15:27:48.687611
421c9160-2d52-4fec-ba83-cee343ed0784    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       492838e1-af27-4170-9f04-44c414a6ac8b    Created agreement: LA-2026-5775 2026-04-13 05:52:44.393598
5f08f2ec-621d-4a79-aa92-81842aa99fe7    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       023bb5e6-d199-47f5-98ac-e56852e328eb    Created agreement: LA-2026-3847 2026-04-13 05:54:02.478801
c1fc3538-b22b-47ed-9f38-522224959b50    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       40512c80-33d1-4387-92cf-5e2de183cd83    Created agreement: LA-2026-4393 2026-04-13 05:58:52.996599
a1488ed7-48d5-4bf2-8b55-2a791f02a078    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       cbc5ff28-d107-4579-b6ae-9821d98d9953    Created agreement: LA-2026-7927 2026-04-13 06:00:26.580214
41899f47-7ed4-4670-b66b-0cbdef6581e5    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       100098a1-7623-45d0-98bb-9cc27df24f97    Created agreement: LA-2026-5059 2026-04-13 06:02:23.310695
86260b4c-e7a2-4d9f-b7e6-03db9d7e5a97    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       4c591c4e-0bb5-4883-9efc-fd68ac6d86c8    Created agreement: LA-2026-7265 2026-04-13 06:06:25.878747
5569cd67-393e-4c54-9e6a-d032e0d9cd3f    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       3a43dba1-7064-404a-885b-235a91e3e3ad    Created agreement: LA-2026-7924 2026-04-13 06:09:56.694358
4606ee1b-d956-47fe-9177-dab35d08c26e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       118851e3-bb70-40b4-baef-e0b166aaeb33    Created agreement: LA-2026-8620 2026-04-13 06:11:06.863813
b9d6e506-f7c1-4223-9bcf-d74b2306549b    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       aa2debbf-65cc-401c-a893-7118db8776dd    Created agreement: LA-2026-5182 2026-04-13 06:12:03.422003
30599c62-e780-4745-9c05-3dcfe5fe3a5e    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       22611492-a4e5-4508-ab53-73603061e29b    Created agreement: LA-2026-3446 2026-04-13 06:13:02.063538
b7f2f0a3-ca55-4c3d-8af5-4ffd8a370e19    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       b547cd06-f025-41ff-ac1f-c737fa25b992    Created agreement: LA-2026-4831 2026-04-13 06:14:33.470503
55962b58-5984-4a41-bb5d-79558e760ba2    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       01023848-27f2-4fa9-9353-898ff9671bb0    Created agreement: LA-2026-4773 2026-04-13 06:15:23.009311
88cb7296-4678-4b22-b27e-2ddf79a57885    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       953f8e4e-0fdd-4c25-b5d5-1675d60f68c4    Created agreement: LA-2026-3801 2026-04-13 06:16:52.02606
03aa83d1-7b0b-4a37-8039-1f90e1868beb    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       ccd73b21-f66a-45a9-a7df-485375938b68    Created agreement: LA-2026-9381 2026-04-13 06:17:47.957302
86ddce8c-823a-414f-b2d4-3b56b78e6c03    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       b63523f0-981b-4213-9cf8-36b308363c6b    Created agreement: LA-2026-0495 2026-04-13 06:18:48.726905
b53d0c6e-bba1-4e64-aab9-f742b7f7f05f    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       24b5874e-1fe7-40a3-9654-3885b72045c6    Created agreement: LA-2026-7644 2026-04-13 06:19:45.876202
bf47d9ea-2346-4b31-9b1f-45f83c24f6d1    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       ed0c7101-2f4b-4594-8e09-b70868861062    Created agreement: LA-2026-4769 2026-04-13 06:20:43.384007
9903eb2e-b5c5-4bef-8eac-119ed0e55af7    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       769d85ae-f864-439a-a401-3ee6f272353c    Created agreement: LA-2026-8436 2026-04-13 06:21:37.021211
61c9f16a-51cc-4e23-8658-2f904c6bb061    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_agreement        agreement       37a6eabf-8f3b-4993-9797-563a9f1b0565    Created agreement: LA-2026-2234 2026-04-13 11:14:51.64919
23f29b2b-12ce-46a6-aa5a-98946609259f    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_agreement        agreement       f92e40f0-3188-4b4b-aac7-2a9386ca9814    Created agreement: LA-2026-6688 2026-04-13 11:20:25.456578
410033d8-e745-4c0b-aef3-68aaabea0299    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 98d9e869-ed91-4c77-856d-826dfcd963bc    \N      2026-04-14 09:44:30.810407
2bd6cbcd-bbe1-4b43-a668-867102c3330c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 233050e7-8ebd-49e8-a8e9-29f505ebb57f    \N      2026-04-14 09:44:57.032936
5c586ac1-7915-41c6-8d0a-8c4069294234    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2ef0ca36-98f0-47ba-b045-1f4ea3efc30c    \N      2026-04-14 09:45:16.792319
6942230f-da65-4127-8a1b-3d258328c68f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 8cd9dbfe-1392-4dc1-9dc2-81e8d222e1cb    \N      2026-04-14 09:46:20.285426
46ecb138-276d-4c08-8d01-73ce8ebf0636    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 31d9a755-6110-4331-9b0f-cd973d3f6150    \N      2026-04-14 09:46:34.685129
f69fbb83-9573-4e4e-9d49-dc56faef677f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 11dd6a0d-2851-4f3a-ab31-ca55fb2d010b    \N      2026-04-14 09:46:48.535486
132479d5-9d18-4505-9a76-8ef2627e6198    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element f5987dba-e80d-4b72-8d3d-14e2371f955a    \N      2026-04-14 09:48:21.699186
761e9123-6845-4f09-a9ff-98e7631a3eda    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    31a91729-398b-4c5c-81b1-89daf72b7fc5    Price changed to 624 for item ClinicMAT - Cepesedan 20 ml       2026-04-14 09:52:08.10256
ef91a50a-7d4b-4b80-bd35-89336cba14eb    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_billing_element  billing_element de9ca878-d8ac-423a-9cdf-a68ab54d8f2c    \N      2026-04-14 10:45:30.260347
f508ffcf-008e-4b47-b1cc-8f3cbee5dec9    853acd7c-4759-4213-ace1-b7da16385a52    admin   delete_billing_element  billing_element de9ca878-d8ac-423a-9cdf-a68ab54d8f2c    \N      2026-04-14 10:45:45.023135
049f9e68-d6b0-43d2-8ff3-70cbbf90e0a4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element bf67e5d6-5379-4943-a6d1-f018997081ad    \N      2026-04-14 11:18:22.525708
c121dc2e-da63-4d41-b382-796d2414adc6    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element c432b946-048a-480c-857e-61d7c524aaf3    \N      2026-04-14 11:18:40.106418
ede7b568-ab8c-4d84-b411-09f835bc1f52    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element ee8a7c4e-edd5-4377-94ee-9f626ea8559c    \N      2026-04-14 11:18:56.79635
459cb2ab-0488-4596-a2bd-2342063c9ed8    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    cde77c22-7efb-47f5-a23f-62c5e1e32016    Price changed to 175 for item ClinicSRV -Sedation Fee   2026-04-14 11:21:05.820929
526c68b0-0f0e-4ad6-84a2-bcd0e1f8ae64    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 911d512e-266e-4bb6-845e-6b4563250907    \N      2026-04-14 11:21:18.934877
8314efb2-c59c-4d74-811e-01c74dba0980    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 54851555-0713-4431-9200-75244872db85    \N      2026-04-14 11:22:51.043245
d7581e13-8d95-41c9-be1e-697e3b9cb49b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 95cdd077-aa67-4d8e-a51c-41839013c9f2    \N      2026-04-14 11:23:29.575841
8b99f16c-fc10-4d04-9a06-c1237afff941    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 0f9bd7b3-3d00-4472-8311-7f83336ddf0c    \N      2026-04-14 11:24:10.88477
ea922d0b-2d14-4359-9cd1-09987f3498d2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 0f9bd7b3-3d00-4472-8311-7f83336ddf0c    \N      2026-04-14 11:24:24.359415
77df5198-4856-4440-ab65-779e11cf157f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element a019f985-2588-4644-8f39-e88e163f13f1    \N      2026-04-14 11:25:32.660133
7d00b859-1da5-4c30-88eb-798ad181ee8b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 729781ab-2ae5-4d5e-a6f4-4af9e4a58ce5    \N      2026-04-14 11:26:14.266655
327342d1-6228-4827-b617-a5de98be9342    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 950166e9-1ae7-4ef2-9413-9429bf76e2bc    \N      2026-04-14 11:26:28.643906
934a35a5-1161-43f1-8748-89df99fb5a8d    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 7ff9cadb-d4dd-490b-b570-c6370ae3d6b5    \N      2026-04-14 11:26:43.777701
b7ea89e5-1118-4c41-87aa-7c43157bc82c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 6fa4e7a0-b59c-4fc3-9a02-0a2953c931c0    \N      2026-04-14 11:31:56.305656
1f64a03e-b747-4e89-90ee-a2f4a3d1ac61    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 8b64c4f3-f0fb-4738-9675-251419520829    \N      2026-04-14 11:32:15.809532
20ae1a16-dad3-4ac6-ab28-ba89e6652196    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     checkout_agreement      agreement       36e479ca-f1d5-41d1-be08-f0d995046e98    Checkout agreement, end date: 2026-04-01        2026-04-14 11:47:43.718863
eb81d841-2db4-49e8-b59a-3e91c9847283    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     checkout_agreement      agreement       bc66e8b5-2972-4793-bf92-e3e45412faff    Checkout agreement, end date: 2026-04-01        2026-04-14 11:48:34.260272
de1ba6c1-eb52-4110-a03f-9a13e834e63e    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 68c90ce3-c216-407a-bddd-17faa8b556a5    \N      2026-04-15 07:02:42.117757
441f5761-c95e-480b-8879-c4b6ebc1e068    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element cd676cc3-9296-4e93-b258-0c57c6ec6681    \N      2026-04-15 07:02:58.467445
1b4b1819-b642-4980-8175-b15ed9cd4603    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   delete_billing_element  billing_element 68c90ce3-c216-407a-bddd-17faa8b556a5    \N      2026-04-15 07:08:59.594872
1e4c1ffd-6997-4b80-8fc4-20f0894f25cc    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   delete_billing_element  billing_element cd676cc3-9296-4e93-b258-0c57c6ec6681    \N      2026-04-15 07:09:01.699886
1ad9a814-ecb2-4f33-982c-4021ab6a94c6    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element a75043da-b8a4-4cea-b4c1-b8be48cf7d34    \N      2026-04-15 07:17:50.607215
7d8ca865-11b4-4d17-b541-f2b92f76d0cf    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element b7520242-0c81-423f-811a-e0a4632f0650    \N      2026-04-15 07:19:38.627368
2c976635-ddd2-41b6-9224-b939c4797d5b    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       9b025149-2c56-4dbd-80ea-2c2849edb1f9    Created agreement: LA-2026-1989 2026-04-15 18:34:41.24441
10616cf8-5566-4f7e-b6f9-aac794146acb    ef15f912-26cd-4a82-b345-2e20f4706490    nixon.silveira@adec.ae  change_item_price       item    8bdc7827-15b9-4b15-b341-08598255ab11    Price changed to 1051 for item ClinicMAT -Gastrogard (7 syringes/box)   2026-04-16 07:01:19.194069
5faa6895-6836-4e2b-afdc-2bb7c3f66ef6    ef15f912-26cd-4a82-b345-2e20f4706490    nixon.silveira@adec.ae  create_billing_element  billing_element b3574fb4-e8b9-4eac-a4a2-c850b37f0f5a    \N      2026-04-16 07:03:05.573591
8f9df521-ffbe-4969-8248-ffb88a950dd9    853acd7c-4759-4213-ace1-b7da16385a52    admin   rollback_invoice        invoice 7c82c57b-dbe0-40fa-9a3f-971b57ef3eb0    \N      2026-04-16 07:05:40.479061
befab87c-a8b9-4ea9-8601-5e6844f1b27c    ef15f912-26cd-4a82-b345-2e20f4706490    nixon.silveira@adec.ae  delete_billing_element  billing_element b3574fb4-e8b9-4eac-a4a2-c850b37f0f5a    \N      2026-04-16 07:05:49.232226
27f0e9e7-18e6-41da-8936-61875d497d7c    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     cancel_checkout agreement       bc66e8b5-2972-4793-bf92-e3e45412faff    Cancelled checkout for agreement LA-2026-0104   2026-04-20 04:08:59.676859
97858fe1-6570-46ba-8daf-4d6c5a5de92b    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     cancel_checkout agreement       36e479ca-f1d5-41d1-be08-f0d995046e98    Cancelled checkout for agreement LA-2026-7522   2026-04-20 04:09:04.533757
89c3fae1-179f-4374-b0bf-50faaf961f4b    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     checkout_agreement      agreement       bc66e8b5-2972-4793-bf92-e3e45412faff    Checkout agreement, end date: 2026-03-31        2026-04-20 04:09:55.257167
a9c6547b-f308-4323-bd24-9e2458470f9a    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     checkout_agreement      agreement       36e479ca-f1d5-41d1-be08-f0d995046e98    Checkout agreement, end date: 2026-03-31        2026-04-20 04:11:12.233995
ce5f0938-6923-4f10-aac8-17a54b4b1388    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element be933ca6-7492-4615-aee2-eecf2f0c0902    \N      2026-04-20 04:20:41.307947
10d7c833-162c-4eba-aba7-ee86054bd572    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element 9f311942-0a2c-4fe1-9d12-f23c7efb6921    \N      2026-04-20 05:03:08.944237
ad08d7a8-4a05-44b9-ae97-fffd8950e242    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element 440b6825-7f0e-4d4f-b8b9-00b28eb9d2e9    \N      2026-04-20 05:04:06.978209
47c6c51c-eca5-40e1-a2f9-189916d1e9a1    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element c9ee8a3c-0692-43af-b3eb-fe9cb12d8d53    \N      2026-04-20 05:04:46.559383
72440f27-6d3e-4177-aada-898647382c43    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element cb46e295-9f87-4a73-a5aa-ced4d2147ced    \N      2026-04-20 05:05:24.563711
e74fdf69-dbb9-4037-9ac0-b7fb22c2afe2    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element 4ad0c3fa-70df-4e4d-92c7-1413f21022c7    \N      2026-04-20 05:05:52.119314
840308a5-7a59-4da5-8bb8-02280bbe2ec2    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element 7f86c8cb-1e82-47d8-bc8c-ff64e136ce5d    \N      2026-04-20 05:06:20.007985
7fd09e9a-2e20-42fb-ad9d-548035705621    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 78aeec3b-b137-40c7-896a-c946d31cb139    \N      2026-04-20 10:35:26.880188
25f9783b-f357-4672-9d7c-91f8014739cf    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 4ea56e7e-f6c8-4b6b-b781-41daca27b4e3    \N      2026-04-20 10:36:11.134855
ac10f234-27a6-48be-871d-9261ed4705cf    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element cdea7dad-1f20-42a0-bc23-b09f48f54413    \N      2026-04-20 10:38:16.686667
f806aec8-9d1a-45b9-80b8-5d016cb2f53e    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element f1ea31c1-466f-45ed-9d19-4fd5bc2af8fc    \N      2026-04-20 10:41:16.091789
129a75c5-5a37-487c-97cc-71d360685a73    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 15e419e9-f323-41e3-95cf-7b691c4a9f35    \N      2026-04-20 10:41:45.439303
c4fbea80-8a24-4ca0-a801-7db2e51a4d3b    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 4f3747e4-6013-4366-be04-e484342ee8f9    \N      2026-04-20 10:42:11.664168
841d6495-3312-4d0c-9d77-89cb2bfa23d1    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element d3536e9f-4f85-44f2-86ed-43034c34bca2    \N      2026-04-20 10:42:32.524227
6157473c-fca9-444a-926e-466c0808c1bf    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 6e3a0387-6215-4cb6-8433-0abb341dec99    \N      2026-04-20 10:42:51.201025
a987efb5-57cf-46f7-a904-a44c3ebba6a0    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 6ee3a2ab-e41c-4118-8807-64280f1d824d    \N      2026-04-20 10:44:13.629894
28ca7710-b2ce-4c02-bb36-867d3219ca7e    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element fc2c55a6-df7c-4aac-9990-c6dc83460ca8    \N      2026-04-20 10:44:28.459322
e7b71e32-2c6c-43f0-badd-f51187b52c81    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element 6ee3a2ab-e41c-4118-8807-64280f1d824d    \N      2026-04-20 10:46:22.153674
7949048b-fb4f-443a-a009-5212193b5ada    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 24144d4a-afce-4b03-9b94-0edee8000605    \N      2026-04-20 10:46:39.60909
0b3498f5-3562-417a-9427-6cfaf77c1265    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element d5bc7651-78ff-4d1b-a731-1a587dfdfa42    \N      2026-04-20 10:47:08.807753
1bda5a6c-739e-48a2-bf41-7e57a611f52e    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element 24144d4a-afce-4b03-9b94-0edee8000605    \N      2026-04-20 10:47:22.031623
f30ee960-0724-424d-b538-26f1fced6ebd    853acd7c-4759-4213-ace1-b7da16385a52    admin   update_user     user    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    Updated user role to: LIVERY_ADMIN      2026-04-22 04:45:39.955614
485a956d-b5b4-4f07-8485-e61d0e61c598    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element ff0e28f6-a278-4b22-a3e8-1b4c2820e692    \N      2026-04-22 04:47:42.476259
8a6464d8-3625-4fa9-a6af-7434d89b8887    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_billing_element  billing_element 37352592-5c3a-40ff-8282-e38c0fc2bf47    \N      2026-04-22 12:39:44.290783
5f5e824e-ac9c-4632-bce4-1d5deae1e83f    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_billing_month   monthly_billing_approval        699aec28-fff7-44af-8b56-6b23998bc556    STORES approved for 2026-04     2026-04-23 08:53:50.695374
5d5ad01b-4f09-4119-b929-4e23a93e4875    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 8e7408de-8f29-4294-8dd4-1669ad4e2b08    \N      2026-04-25 10:17:12.961819
dbf3f4ac-5419-49f1-abbd-2a9249a15bec    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 53dccf2a-c0b8-432f-932e-43c81709b41b    \N      2026-04-25 10:30:22.008858
358f0f76-b787-4054-896b-d29b10d882bd    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element df24afe7-0d85-4ff2-9275-56127485d27d    \N      2026-04-25 10:30:22.487451
9e72f693-e924-4b62-9405-ba16703294c0    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   delete_billing_element  billing_element 8e7408de-8f29-4294-8dd4-1669ad4e2b08    \N      2026-04-25 10:42:21.270927
3f8f11b4-9986-4d37-90a3-4ab0a17f4f36    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 66124152-e585-47d1-87bb-83991d60879f    \N      2026-04-25 10:47:01.884609
33d470ee-4ae1-4dc9-bdb4-a3f68e2b71d2    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   approve_billing_month   monthly_billing_approval        3c17c2cb-2a86-47d2-9152-78a29d9bccd5    STORES approved for 2026-04     2026-04-25 10:47:28.45192
daa3a2a5-c84c-4736-adba-c0255fe98f9f    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   approve_billing_month   monthly_billing_approval        3b7c20b3-a657-49b1-b667-efa41510ac20    STORES approved for 2026-04     2026-04-25 10:47:38.61525
407afb4a-3a93-4250-965c-17811ff05fb2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 8cd9dbfe-1392-4dc1-9dc2-81e8d222e1cb    \N      2026-04-26 10:42:20.052966
75589650-e9b6-4f40-aea6-765374337f4c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    edc7d7ae-4e8b-4a37-8aa4-00bee9186849    Price changed to 200 for item ClinicSRV -Ultrasound Exam (Brief)        2026-04-26 10:42:58.159536
2d426a85-8336-4f8c-96b1-157bae0546ba    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 61db960f-4b57-4a5c-952c-40cf2787ccf2    \N      2026-04-26 10:43:02.185452
1b5116ca-4a1a-4e7b-8a64-9ebfac066ce9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    67bd15c4-8a78-47ee-84ac-4caffc4e0dbb    Price changed to 315 for item ClinicMAT -Enalees Streptococcus Equi     2026-04-27 13:39:26.558732
237ca82a-18ce-45d4-a826-0f2e052aadad    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element a81cb9b5-46fe-4c98-b0fb-8748e7066227    \N      2026-04-27 13:39:51.391788
39c42796-21a0-494c-9842-0542b069d62e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 8dafc397-8180-47c8-9fa4-eae19e611a07    \N      2026-04-27 13:39:51.94783
fde52cc2-2f87-4270-b1c2-4401054e2e36    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 313f689c-5fc7-4cda-8604-cc6cad60eab1    \N      2026-04-27 13:44:15.568964
da90467b-18d4-4ec8-a2a8-4dc9808086f4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2d2f2bc9-ed07-444f-92e3-577597ff31c2    \N      2026-04-27 13:44:16.009591
3b4c2761-bb56-4e68-9894-0e0746afb2a9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    3d1a7667-7ce9-4b29-aff4-bc6b5d2010c1    Price changed to 800 for item ClinicMAT-Equipalazone Powder     2026-04-27 13:45:06.860399
10e74b87-3290-46e6-883a-f253c4c79e48    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 33f21ba8-b10e-4842-aa3f-c2dd33d771f0    \N      2026-04-27 13:45:19.676957
03ff6c48-9dd3-43cd-82e9-d46bfd5dbff2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 16ef95cc-6744-4162-8a10-132be7eb52d9    \N      2026-04-27 14:03:33.61092
61f34a7b-6758-4b18-ba32-378fd5f10af2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        84c66e0a-f847-4136-a6e3-f8bbebd50dd8    VET approved for 2026-04        2026-04-27 14:05:31.714121
c0eb1ffe-462d-48ad-9bea-e535e930734e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        3836f7a6-f4fc-4fae-9b4e-f457dbc533d9    VET approved for 2026-04        2026-04-27 14:05:46.786258
87134ddd-709b-4e36-b1dc-ebd9b3ee3a47    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        48fbb2e4-bfdf-4116-aace-ed15b36c2788    VET approved for 2026-04        2026-04-27 14:06:06.501478
64936107-9f51-49d5-bb4c-b494304cc2ee    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        f04ad57b-5194-4874-b476-cf5734beae3a    VET approved for 2026-04        2026-04-27 14:06:16.301035
afdbd55e-b401-4e56-85af-8d399ce37e80    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        4cadd233-ab31-4261-804a-27da14db053a    VET approved for 2026-04        2026-04-27 14:06:26.470769
62ac2d87-73d4-463c-820f-2b803eeb7330    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        37e75419-add5-4ba4-b52d-20a337d90493    VET approved for 2026-04        2026-04-27 14:06:35.190682
4dc34706-9673-4ce6-8ece-0ecad1cf0f06    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        bbfabe4c-94fa-4473-92bd-371a22c53727    VET approved for 2026-04        2026-04-27 14:06:49.08632
3c22de5a-6024-459b-910b-d4009475b595    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        a561b140-577d-4785-83c3-75e272b06558    VET approved for 2026-04        2026-04-27 14:06:51.100646
4e2fdac8-f112-43b5-a6fa-1fc952d4ac47    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        56db7e28-2832-462b-8227-217c096dfd76    VET approved for 2026-04        2026-04-27 14:06:54.887569
e133277c-377f-4959-be62-8093d94881e6    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        4de8cce4-c20e-44c9-9fa8-cf56da1d2624    VET approved for 2026-04        2026-04-27 14:06:57.701533
4b7b349f-0be0-41ec-977b-fcc65d265da3    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        1e87fe49-fa75-467b-934a-99ac7c724488    VET approved for 2026-04        2026-04-27 14:07:00.789895
86ae3837-34f7-404b-aefb-fa2d1993f293    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        7acb95bb-c575-42a3-b8b9-5e1b37dd6d34    VET approved for 2026-04        2026-04-27 14:07:06.552647
8d827801-c06c-40f6-8216-e24702a7e107    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        aa9664c2-c253-4dcc-ac49-931239a06ace    VET approved for 2026-04        2026-04-27 14:07:08.805327
fb8a5ab6-3aa5-4608-86ae-828200f079e9    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_billing_month   monthly_billing_approval        d4518bdd-7a4a-42d2-87e8-231d1a1a5458    VET approved for 2026-04        2026-04-28 05:35:45.596152
b53e0123-f8a0-43ed-bd0e-e1cc597e4fee    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_invoice  invoice 140ae01b-3d42-4bb0-a651-d441c3efe38a    Created invoice for billing month 2026-04       2026-04-28 05:35:52.096194
9b7e660f-85ec-4b36-ae65-6f129744dec9    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_invoice  invoice bc88bf37-fd3c-43d8-9b39-dee15985a4e4    Created invoice for billing month 2026-04       2026-04-28 06:01:34.287534
452f3dae-12ed-438a-b14b-786ef706d4cf    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_invoice  invoice 3c31925a-5ef1-49c9-8aff-e7cf67cb19c0    Created invoice for billing month 2026-04       2026-04-28 06:01:54.859851
b1d5213d-c701-4fbc-9922-85ef4119d676    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   approve_billing_month   monthly_billing_approval        43549c25-8f99-4668-aac5-42d77a539c18    STORES approved for 2026-04     2026-04-28 06:29:10.997811
8c86bd15-d493-491a-9fa0-9c871c69f360    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   approve_billing_month   monthly_billing_approval        c6279da9-c25d-49e4-9612-b99080692a9e    STORES approved for 2026-04     2026-04-28 06:29:14.175921
ba399366-77ce-4e2b-8e26-856041295c5b    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   approve_billing_month   monthly_billing_approval        bfe818cd-daf0-49b7-b582-c829ab49f631    STORES approved for 2026-04     2026-04-28 06:29:21.078636
7b58722b-e3c4-4da6-943b-3016637e91fe    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   approve_billing_month   monthly_billing_approval        277a15ec-dde3-4744-ae00-a32bf360cf1f    STORES approved for 2026-04     2026-04-28 06:29:23.309249
5643583b-36ac-4462-bce5-30074570316e    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   revoke_billing_month_approval   monthly_billing_approval        277a15ec-dde3-4744-ae00-a32bf360cf1f    STORES revoked for 2026-04      2026-04-28 06:30:14.132723
9bd0ad68-0827-4720-a2b8-bc3e103ec79b    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   revoke_billing_month_approval   monthly_billing_approval        bfe818cd-daf0-49b7-b582-c829ab49f631    STORES revoked for 2026-04      2026-04-28 06:30:15.279388
2901f2d4-ea1f-4b8f-99f3-8261627328c1    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   revoke_billing_month_approval   monthly_billing_approval        c6279da9-c25d-49e4-9612-b99080692a9e    STORES revoked for 2026-04      2026-04-28 06:30:16.886882
3a721fef-68d2-4ee7-bfe0-1deb4459c978    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   approve_billing_month   monthly_billing_approval        c6279da9-c25d-49e4-9612-b99080692a9e    STORES approved for 2026-04     2026-04-28 06:30:19.483672
8f91f1f2-0489-452d-9d0f-bc677f691172    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   approve_billing_month   monthly_billing_approval        70639747-3c0a-4226-9b08-9932fde70329    STORES approved for 2026-04     2026-04-28 06:30:31.319814
5ed6e4b9-dda3-40fe-88c8-2870068bee81    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   approve_billing_month   monthly_billing_approval        2bcfb5ee-7acd-466c-b64c-7062188c69f5    STORES approved for 2026-04     2026-04-28 06:30:52.850239
b2f6dd9d-489c-4c52-ab14-afa031282dea    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_invoice  invoice 4e96dcba-e4e8-4ccc-8ae4-b43fa3880b95    Created invoice for billing month 2026-04       2026-04-28 06:35:46.962141
f905111d-5187-4731-8417-e998e1aa6345    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_invoice  invoice a1c6fcc8-f688-4575-b089-780f1e174c58    Created invoice for billing month 2026-04       2026-04-28 06:35:57.62528
3375bdcf-8a56-436f-9882-99c590f7307a    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     create_invoice  invoice c0234e40-99f7-4723-b737-357c08de3025    Created invoice for billing month 2026-04       2026-04-28 06:36:05.084257
e55751a0-0a27-414a-bded-e8e774613e71    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     checkout_agreement      agreement       bd4d6227-5901-4ed9-8f36-54c3c149c7ae    Checkout agreement, end date: 2026-04-27        2026-04-28 07:13:50.03989
1635082a-4435-4ed2-8b40-d46bbb6a02c0    853acd7c-4759-4213-ace1-b7da16385a52    admin   rollback_invoice        invoice 140ae01b-3d42-4bb0-a651-d441c3efe38a    \N      2026-04-28 07:48:32.697361
52acdc3a-072f-456d-8b58-4088d828d144    853acd7c-4759-4213-ace1-b7da16385a52    admin   revoke_billing_month_approval   monthly_billing_approval        d4518bdd-7a4a-42d2-87e8-231d1a1a5458    VET revoked for 2026-04 2026-04-28 07:48:43.148599
3b7d3fe8-c0bf-41b1-a885-881c9e1e6766    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 61db960f-4b57-4a5c-952c-40cf2787ccf2    \N      2026-04-28 10:54:36.310286
e4988a83-0395-40f2-af91-83823c394ebf    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 5d9d0ab2-aac6-4562-84f7-84b7e01bc59c    \N      2026-04-28 10:55:21.000276
394997b4-6cf7-45b2-af57-3e91de6444a8    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        2d9768a3-7762-4f66-8f93-562a3fa6e254    VET approved for 2026-04        2026-04-28 10:56:35.47316
e683bcd6-c64a-4241-983b-a50fc0450936    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        2d9768a3-7762-4f66-8f93-562a3fa6e254    VET approved for 2026-04        2026-04-28 10:56:45.130425
eb339b7d-7732-458f-bdc3-36367662f650    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_invoice  invoice e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    Created invoice for billing month 2026-04       2026-04-28 11:02:04.633386
905561a4-372c-4474-8984-8f5797d8812a    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     cancel_checkout agreement       bd4d6227-5901-4ed9-8f36-54c3c149c7ae    Cancelled checkout for agreement LA-2026-9953   2026-04-28 11:40:22.577628
c6950f0a-a63a-4987-9c16-22ee2bc67e3a    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     checkout_agreement      agreement       bd4d6227-5901-4ed9-8f36-54c3c149c7ae    Checkout agreement, end date: 2026-04-27        2026-04-28 11:41:12.328417
873e12e6-411b-4216-8d38-cb462599b6f6    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     checkout_agreement      agreement       17b270a3-9b9d-4336-a47d-41a3e0827675    Checkout agreement, end date: 2026-04-23        2026-04-28 11:43:37.606617
e96a7cfa-53e6-4bd4-8dcf-fbccbebfc650    975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     checkout_agreement      agreement       72fba684-3a74-4a4a-9b6c-c21f69482130    Checkout agreement, end date: 2026-04-29        2026-04-29 04:15:18.426577
08160b0e-64b2-41b5-800e-4fbd04730ecc    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       ea0db11a-b11e-4702-9c7c-3016963760ae    Created agreement: LA-2026-2200 2026-04-30 06:43:52.803275
aacba2fb-1a14-452f-b7c0-cc5e27c50d72    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       de7d1200-1908-4458-a02c-1e8d437ea3c5    Created agreement: LA-2026-8978 2026-04-30 06:44:39.493086
84a53746-b50a-4039-b677-f0696e20b1bd    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       b4e9ffd0-976f-492a-8324-5bbd870e2e19    Created agreement: LA-2026-4054 2026-04-30 06:45:24.575446
2e6eb364-2a77-4ef9-9a86-3a7dc066c7f5    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       28925223-03f6-48ec-8e93-219596159d5d    Created agreement: LA-2026-0017 2026-04-30 06:46:10.534735
8abb3eed-781c-469d-bd22-414c4035a42a    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       ec25a7b6-fd7d-40f5-b771-bd1f083f3525    Created agreement: LA-2026-7797 2026-04-30 08:12:08.359444
b902e6af-acce-4ddd-8436-5f6f168f3069    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       01b2c104-a7ce-487c-9a6b-77d815d57dad    Created agreement: LA-2026-0402 2026-04-30 08:14:11.616999
0ac10f0e-1ffe-4372-bb09-57b63c9933fc    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       6f387363-b896-4ccd-8019-2efb7c3227b4    Created agreement: LA-2026-4732 2026-04-30 08:15:55.259069
91a7dbf4-9ae1-49ca-b25f-2a32fd7c3641    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       cc3a2e05-86a2-434f-9e32-fed376886edd    Created agreement: LA-2026-2484 2026-04-30 08:16:43.011081
16d131f3-b305-4e6a-bfe2-e246dd8fd2b9    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       3680a313-2b02-45fb-92ed-65d918b9fd63    Created agreement: LA-2026-0426 2026-04-30 08:18:00.970532
128f25f0-0b26-4ecd-b398-052982b47348    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       cfb5dbf4-9e82-4a73-ac68-903b5c34be3a    Created agreement: LA-2026-3144 2026-04-30 08:19:13.641255
1da1aed4-e66f-43b4-917d-a4e5dfc0c8bd    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       b119218e-858a-4c49-a7e6-922b8867bd3a    Created agreement: LA-2026-9020 2026-04-30 10:50:29.065263
da7b08e4-91f4-467a-9e62-44346175c6c9    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_agreement        agreement       8333f845-50bc-486c-a59f-49ff8f1eb377    Created agreement: LA-2026-9975 2026-04-30 10:51:00.365443
346d0fc3-836c-4a65-a9ac-dc6b0e4400db    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae checkout_agreement      agreement       bee8af2a-5fc0-4624-a5ab-7b9eb45f8cfa    Checkout agreement, end date: 2026-04-30        2026-04-30 11:45:48.693451
1ffa1ea5-b630-478c-890d-6217234cd959    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element f887f729-25e0-4820-913d-bac718f85f72    \N      2026-05-01 07:27:29.177503
3b5f2a7e-ffd2-435f-9600-962bb436f414    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element f887f729-25e0-4820-913d-bac718f85f72    \N      2026-05-01 07:30:29.02318
c06876ad-e310-49d9-a54d-33a78d60432f    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element f2fb410f-249a-45ad-a74c-f665281e4aea    \N      2026-05-01 07:32:46.803205
817915d2-d027-4025-8f34-a76183c56c9b    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element ac704e88-ae65-46b4-ac50-99ec89883836    \N      2026-05-01 07:33:49.972454
ed7bb7b4-c620-4171-8be3-6a12be2ea9f4    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 51636f09-98e6-4bdf-ae28-b2f9540154f4    \N      2026-05-01 07:34:05.218845
9fc388d2-d8e3-47b7-917e-f393b028f55a    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element d40aeee3-51f4-4bf6-b8bd-5f307628b4bc    \N      2026-05-01 07:34:22.289476
7e596b49-4021-4a8d-8566-452de3c2fa92    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element 51636f09-98e6-4bdf-ae28-b2f9540154f4    \N      2026-05-01 07:34:50.256984
36fa9a63-a4ae-4ac7-986a-e9748a3f0480    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element c5e40360-c4e4-4d7a-aca1-af66846bdf07    \N      2026-05-01 07:35:06.598338
0c9ca953-493e-4f0b-a768-a5e3eeeead13    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_agreement        agreement       98176849-c1f5-4bbd-8041-c9b4f3270c44    Created agreement: LA-2026-8895 2026-05-01 08:18:20.004639
e95a3a57-50ac-4cb0-a78e-7ef03f20fec4    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 34c2ca14-eb56-421e-b0b9-89b998bd09f2    \N      2026-05-01 09:17:47.545811
a0fce64a-9f6c-403b-b8eb-8a90cd70ece5    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element 34c2ca14-eb56-421e-b0b9-89b998bd09f2    \N      2026-05-01 09:17:59.92131
868de33c-548d-4bba-b73f-0a2c05367498    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 343276e3-1801-42eb-961e-c9cb6c2f5625    \N      2026-05-01 09:30:38.154588
637f7b54-9a98-4bb4-865e-3cc4b42d7670    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae update_billing_element  billing_element 343276e3-1801-42eb-961e-c9cb6c2f5625    \N      2026-05-01 09:45:04.769109
20aab462-3a4c-45d8-81af-cb94b9b34b98    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_billing_month   monthly_billing_approval        0925c168-8e2e-4fcc-b07d-3731d15d0139    VET approved for 2026-05        2026-05-01 10:09:53.092227
de6296e5-3686-4330-8e6e-b18a3717cd35    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_billing_month   monthly_billing_approval        befc6786-4bc3-4886-8f55-04fffc6a8dd6    STORES approved for 2026-05     2026-05-01 10:09:53.941795
3a8e2671-46e9-4c83-adcb-859094bf47f0    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_billing_month   monthly_billing_approval        338cd23a-7349-411b-a4bf-14679314498d    STORES approved for 2026-05     2026-05-01 10:10:15.185017
d1e5a897-9b77-433d-9267-3d487a6b0906    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_billing_month   monthly_billing_approval        7540c0a9-27a0-44ff-8972-db828aa1b164    VET approved for 2026-05        2026-05-01 10:10:15.994158
5153699b-5711-4b2e-9bd8-9b7deb55c989    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 32eeaf8f-7163-4137-b055-f447aefb4dee    \N      2026-05-01 13:23:30.912332
df66c5a1-fc5a-4d43-9037-da5dd50d49d9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    252bd6ae-6987-4108-8414-d014709cc641    Price changed to 150 for item ClinicMAT -Intralog 3ml (12pce/box)       2026-05-01 13:39:04.225217
adb55d80-c8ea-4452-8775-ae890044cb1b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    252bd6ae-6987-4108-8414-d014709cc641    Price changed to 150 for item ClinicMAT -Intralog 3ml (12pce/box)       2026-05-01 13:39:14.577743
75f17b2f-75b4-4860-80cc-0864e5ef28c9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    28ce5e3e-5d76-48c7-ab47-23b36a469f86    Price changed to 300 for item ClinicSRV -Joint Block/Medicate - Stifle  2026-05-01 13:39:36.435894
74e8a156-ec32-40ae-9760-5fbaaea58105    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    28ce5e3e-5d76-48c7-ab47-23b36a469f86    Price changed to 150 for item ClinicSRV -Joint Block/Medicate - Stifle  2026-05-01 13:39:56.314025
b0890467-f40b-4ddd-939c-4fc2d63c156f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    28ce5e3e-5d76-48c7-ab47-23b36a469f86    Price changed to 300 for item ClinicSRV -Joint Block/Medicate - Stifle  2026-05-01 13:40:05.437066
456dabe1-5af0-4244-a46d-8ccc50d2d5bf    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    952061b6-9688-4585-96a6-e69b69db106d    Price changed to 500 for item ClinicMAT -Phenylarthrite inj 100 ml      2026-05-01 13:44:10.315228
75d6d81d-b63d-4d16-99aa-e38734e30597    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    952061b6-9688-4585-96a6-e69b69db106d    Price changed to 500 for item ClinicMAT -Phenylarthrite inj 100 ml      2026-05-01 13:44:29.412809
ba804d20-048d-45c5-b8a5-a4918417b424    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 877185e5-7048-44fc-98db-3aa0defdbd5e    \N      2026-05-01 13:44:49.198227
a7296158-b8a2-4c25-ade1-c1578514ad81    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 72dc7eac-7336-4a35-90ed-4ecaf53ca940    \N      2026-05-01 13:44:49.649627
df80acdc-2dc2-498a-87a1-bd75756049fa    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 9962bc1a-cffc-4729-bd91-f47e1942dde7    \N      2026-05-01 13:44:50.073026
68c3154d-6d55-4e30-8e3f-316e233b3f7a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 6988d106-17d7-4504-9845-18b910b11153    \N      2026-05-01 13:44:50.592756
5b34002b-9abd-41dc-9849-199ec9a85fa9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element a0cd43a1-4495-48eb-806e-b9195d536c5c    \N      2026-05-01 13:44:50.98289
5417f71f-6aed-4c70-a76f-7bb699a6ade9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 7332e8e1-f3d0-41ef-8c8d-09995bba0e21    \N      2026-05-01 13:44:51.390536
afd99ef8-faf2-4868-8a8b-240363815674    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element d0253f62-770b-44ad-bd67-56f6819410a0    \N      2026-05-01 13:45:33.388076
80071d66-4c91-4c04-934b-4424b762d1b0    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 9a05cf11-b58d-493e-b4bf-b207f4d65cf8    \N      2026-05-01 13:45:45.97674
a06edb8b-2aa3-43dd-ad0e-bd35ece8b344    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 7071e147-3eb6-416d-bfea-22bb9c461fd8    \N      2026-05-01 13:45:57.738065
a1a674bc-2e2e-4cb0-af88-8f674c082298    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 1d1606fb-47b8-4d13-a8f8-e51fb8ba0741    \N      2026-05-01 13:46:10.842352
5acc7147-aeea-4f32-8bb7-ed8085963b56    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 0e0390ae-c5a4-4491-bc96-200ea04606fc    \N      2026-05-01 13:46:23.207047
73421f0b-e2b8-4b20-b3e4-4acd650b66fa    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 05008140-f79c-46a2-8288-d87b3ccea64a    \N      2026-05-01 13:46:30.60532
b58baf5b-609c-453b-a12f-3cc88caacf57    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 4aadbc49-3837-4bca-bb23-bd86371ed9bf    \N      2026-05-01 13:46:40.423532
660edbc7-da82-4f63-9b28-f0059ed9d453    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element ad746c14-78c3-4dc0-aeea-6919e76fd5e6    \N      2026-05-01 13:46:48.754829
0e259e06-72bd-4676-9909-776fa5542f91    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    d9300ff4-7a1b-4d9f-8154-69c28962fe49    Price changed to 130 for item ClinicMAT -Flunidol 33g Paste     2026-05-01 13:57:13.513295
8d23f6d3-525f-43ce-b84f-183bdadd799f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    d9300ff4-7a1b-4d9f-8154-69c28962fe49    Price changed to 780 for item ClinicMAT -Flunidol 33g Paste     2026-05-01 13:57:33.605494
9a51edd3-4b2d-4204-97e3-ab078963fe2b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 9ceb02e4-b10e-4b56-9674-c6d661100dd8    \N      2026-05-01 13:59:19.364559
b7dcef18-a9b5-48fc-8bef-8e616c615cf5    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element ffe8379d-b62c-4201-9736-397a8ed891fe    \N      2026-05-01 13:59:19.814396
38d38e2a-c088-48c2-b92a-a333f8d36a97    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae update_billing_element  billing_element 343276e3-1801-42eb-961e-c9cb6c2f5625    \N      2026-05-01 20:47:50.148312
566a86c4-8915-4133-a32b-31cf909911a4    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element 343276e3-1801-42eb-961e-c9cb6c2f5625    \N      2026-05-01 20:48:08.892623
cb5f93d4-2f8f-40c5-954c-c5613d4f6363    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 7c2345a5-008c-43a9-8d67-a25a5f2a2af6    \N      2026-05-01 20:48:35.884358
71cf4ea9-f28b-4e8c-acdd-bec81d597de6    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element c5e40360-c4e4-4d7a-aca1-af66846bdf07    \N      2026-05-01 20:49:05.070188
4504aa8b-8a1a-4eff-b06a-9c8218deb409    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element f2fb410f-249a-45ad-a74c-f665281e4aea    \N      2026-05-01 20:49:06.999495
8b11f4fa-454d-48c4-a597-21ba4d589f98    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element ac704e88-ae65-46b4-ac50-99ec89883836    \N      2026-05-01 20:49:09.705917
ab3614e4-cd22-43eb-a54a-63455cee9723    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element d40aeee3-51f4-4bf6-b8bd-5f307628b4bc    \N      2026-05-01 20:49:11.18936
07bf4248-ecb0-4763-aa90-436ba2dff5d5    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element b27451e0-cfd5-493d-95b2-fb24757aacc4    \N      2026-05-01 20:49:37.097821
e088ffc0-3a39-4c50-a794-aa66256db684    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 7691298e-650c-4bb2-aee3-7f91d8536804    \N      2026-05-01 20:49:55.746382
090c910c-3445-4c0a-888a-9c5202951ace    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 96c7587a-bc0a-4713-955b-3b5291e6c9e5    \N      2026-05-01 20:50:13.644624
4e3f6b7a-6432-45c8-9b12-c9da6edea72a    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element d56170d7-bf7e-44c8-9c19-ed85138b7b0a    \N      2026-05-01 20:50:27.435139
c558e35a-8b4c-4a3f-89e1-ef9c9bcdd509    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    6069d3b6-f009-4c64-9f6b-2b465729df72    Price changed to 340 for item ClinicSRV -Export paperwork + blood sampling      2026-05-02 13:28:07.456166
a1e8634a-8b56-4490-82ce-f3f53d217e5c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2fc04f0e-8409-431d-a25e-d45e3e7e3786    \N      2026-05-02 13:28:33.542788
a176b1a3-4260-411d-ba63-853bd37f775c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 5e4bb2db-f39a-48c0-951f-e8a1e68fb9c3    \N      2026-05-02 13:28:52.575749
13982c3c-1a9e-4878-818f-d1d1a39a1946    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 4d5f69db-5f60-496b-b7b7-a61084079987    \N      2026-05-02 13:29:04.859234
1bdbf06a-59a8-49b6-82a5-6ea03ef3e411    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 011f3ce2-ac1b-4ee0-875d-fa5b00fe1c99    \N      2026-05-02 13:29:22.017636
9e11fd6b-d638-45e4-98c4-7f02a8d9ac1a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 92fed059-51cb-4598-a852-635cdbbcc192    \N      2026-05-02 13:29:55.385053
52412b3f-a486-4fc4-9cbc-1f7a005c125f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    cc0a7c79-e7b4-4145-a0de-91f9e9e8deca    Price changed to 150 for item ClinicSRV -Nasogastric Tubing     2026-05-02 13:30:46.476768
ef58188d-6693-4645-9dc8-4bdefaca9dee    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    66765bc5-f937-4071-b6b0-19f979447d20    Price changed to 56 for item ClinicMAT - Kentuky Gold drench    2026-05-02 13:31:44.079141
720c5212-b553-4ff5-9605-56008fd4e89f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    dceba4f6-a5bc-4a50-97eb-008121b1489b    Price changed to 300 for item ClinicMAT -Colix Injection 50mg/ml (100ml bottle) 2026-05-02 13:33:03.73554
8a90fa84-a577-43a5-b743-10a0d0b7dc80    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    f1383820-34d0-46c1-af5d-b0368a043731    Price changed to 378 for item ClinicMAT -Buscopan Compositum (100ml bottle)     2026-05-02 13:33:52.229358
e659847a-e6dd-4ea6-bc7d-96a500bc1299    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    612e5ad2-02ab-4994-9a3d-b056503c561c    Price changed to 250 for item ClinicSRV -Ultrasound Exam (Abdomen)      2026-05-02 13:34:44.508228
8d73c73d-6e06-4050-9803-8f46d027fd72    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    cb977323-d2c1-4c9c-864c-f589e8196dc6    Price changed to 500 for item ClinicMAT -Xylazine 100 (50ml bottle)     2026-05-02 13:35:34.382157
f52c222c-276d-452e-aa8d-4741128a6ebe    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 6554e95e-d21a-4668-bc1b-5e687d071967    \N      2026-05-02 13:36:16.909944
79513f23-3485-407d-8b2e-1989e8e35dec    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2827b892-080a-4891-a76d-efb5d96ce2f6    \N      2026-05-02 13:36:17.400942
6d19e311-5e9a-4ea6-88f3-dfd6aba9dd4c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element e0a2d8c8-2d29-4048-8214-a000ca1b560e    \N      2026-05-02 13:36:17.843901
3cc2e2e0-d115-4c9d-a331-5b2181fbb516    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 4061bcde-deea-4eb5-87c8-32d0aea07b18    \N      2026-05-02 13:36:18.446247
84ef2c98-1465-4dab-af91-a50fba575079    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 43388791-9bd4-4dad-a024-49150d452f16    \N      2026-05-02 13:36:18.905427
4106e522-75d8-4c81-b163-bcc27e0e1ade    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 76640e02-6678-4579-9f18-4dd45bac046b    \N      2026-05-02 13:36:19.538519
6c22ee68-778c-49fe-9327-4f0e43355eb4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 18f3366f-38b8-429d-848c-3fe653a2551c    \N      2026-05-02 13:36:20.045114
c73a3f80-d111-49d1-b69f-942e4870be9a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 60e128f7-1f36-40b5-a357-a39c811f665e    \N      2026-05-02 13:36:20.543698
6a5f3dd3-ca86-452b-9994-c3ca6c05d759    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    1edb2d92-f0d7-428e-8866-951b4dce645f    Price changed to 2500 for item ClinicSRV - Alpha 2 Macroglobulin (Kit, blood draw + processing) 2026-05-02 13:45:23.324192
dca55dba-a0eb-420e-9589-8a32b9103eae    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    1edb2d92-f0d7-428e-8866-951b4dce645f    Price changed to 2200 for item ClinicSRV - Alpha 2 Macroglobulin (Kit, blood draw + processing) 2026-05-02 13:45:51.813318
9a8b1558-f55e-4cae-ab67-1f12774a14f2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    9e2ec26d-2c40-42ca-b10a-aa241f21c6bf    Price changed to 300 for item ClinicSRV -Joint Block/Medicate - PIP     2026-05-02 13:46:44.186616
125b51fb-2284-4ee0-ba3b-899ecd5da8cd    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    4dda5637-1500-46fd-83e0-59f79a3caf95    Price changed to 350 for item ClinicSRV -Joint Block/Medicate - Sarco-iliac (Ultrasound guided) 2026-05-02 13:47:30.181764
e10e13c4-08da-4e81-a6a4-c179ba914365    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 3aa2d2da-7b58-42cb-9b08-8b3365e36289    \N      2026-05-02 13:48:09.562205
650ebbb0-db76-4e6d-8109-d2c3934d733a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element d041c226-2df8-4810-af1e-720a5bf2c923    \N      2026-05-02 13:48:10.043168
a495e481-12f1-424e-a3a4-953d4826f75e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element db274b78-fbc2-467d-b61e-e561671c1636    \N      2026-05-02 13:48:10.510336
e1e6731b-89a5-4d33-9e7c-cd86aea90cb2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b424d2e9-7571-42b5-b84c-97f47eb2bcf9    \N      2026-05-02 13:48:10.960058
76b66b38-c862-4b47-83aa-3540cff0ee0b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 57e02fa3-5e4b-4ba9-b27d-43312ca607db    \N      2026-05-02 13:48:11.424024
2b20bb67-3f4f-4568-a3d2-844c2e47ebca    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b5139dc6-831e-4e75-bd9c-6a83a314ebaf    \N      2026-05-02 13:48:11.921611
70642b53-5c11-4bef-a4c4-015b8f6f7336    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 6dafe710-5b03-42da-83a7-7321537aca5b    \N      2026-05-02 13:48:12.430808
71718d13-5877-42c3-a11a-66954cad77ea    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 4d00aa9b-1b19-46c2-8ec5-4240dc881668    \N      2026-05-02 13:48:12.852265
9088730c-894d-4aee-ba0e-48b8c9d2a136    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2b5011c0-786a-40c0-890a-477fb89192fc    \N      2026-05-02 13:48:13.283037
5d9c7fce-b3cc-418f-9ce1-ed0b3fa7eb91    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 21e8ecab-b077-4f66-a2e8-a32ef190a16a    \N      2026-05-02 13:51:39.458577
1bde924b-df9e-4c17-8d82-bc3ab8e9afb6    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    3bba8890-8f31-4721-a1eb-23b1bc82b540    Price changed to 12.50 for item ClinicMAT -Vetwrap      2026-05-02 13:54:28.366696
684101ca-ef07-4a4a-b5e1-246a3dc6289a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element eb9ecdfb-c619-4c87-a429-1faf8cc333f1    \N      2026-05-02 13:54:58.290068
06fb53de-fbda-4e1f-850a-3a88498e05cb    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element c423cba8-13d1-4a86-bd4f-93fc9df3823c    \N      2026-05-02 13:54:58.795782
0a52c8d9-28f2-459a-8179-28425211ea85    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 91d3270b-9d11-47a8-ba85-0f201cc333ed    \N      2026-05-02 13:54:59.239375
c0ab6089-59b6-4488-bb46-a64dfae4aeed    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 95561cd4-b096-411e-bac4-e93ca01c4a2f    \N      2026-05-02 13:54:59.78592
a03df78f-aee0-4fb0-bd89-084e20fed686    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 9e85fdcd-73fa-4ca7-bfb4-1c15be61b86c    \N      2026-05-02 13:55:00.211463
2ce509be-2801-482e-b6e0-123f727b49de    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element c342278f-dd8b-4b19-8cc3-678f86ecd54f    \N      2026-05-02 13:55:00.707575
e74ee8f1-fe65-4adf-9e84-d3c8a9364d0c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 082cd654-3cf2-4114-b1ed-89f5951ba9fe    \N      2026-05-02 13:55:01.144977
86bd1f53-4946-440f-a7e6-d99b6b22428c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element a23dfa9e-a63f-409c-a02c-f61eb9903d30    \N      2026-05-02 13:55:01.731374
14e08226-4df6-4d2f-a532-c61e206491d5    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 20cb0c32-2ad6-4c9b-85db-343a2908b12b    \N      2026-05-02 13:55:02.187328
527236b6-c28e-44f0-8874-a4fc8cc93a22    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 18f02310-ff40-4cc6-9e0c-45cf4c1c2ce8    \N      2026-05-02 13:55:02.651561
89b8a824-84ba-4d5e-b428-6bfb6b28ad62    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element f14d1b1f-7bbf-460f-9840-d4a92ef8243e    \N      2026-05-02 14:02:59.844451
222d5527-6daf-4c21-9cee-1060c34f48f7    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 71c02bcd-0f85-49fa-9cc9-b53d5cdab7b8    \N      2026-05-02 14:03:00.337359
a9671115-e0e4-4bf3-9305-805c413ceac2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element f14d1b1f-7bbf-460f-9840-d4a92ef8243e    \N      2026-05-02 14:03:29.508306
a0e39968-d2b5-4c36-8648-39384ec93ec1    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 71c02bcd-0f85-49fa-9cc9-b53d5cdab7b8    \N      2026-05-02 14:03:32.050349
4d894b7e-c67c-49f2-a6e2-1b5d52d082fd    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_invoice  invoice 50f15835-253c-4d88-9358-02769da532ba    Created invoice for billing month 2026-05       2026-05-02 17:27:31.66517
0523abc0-93c2-4136-95ad-72f59e81ee44    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_invoice  invoice 3d6f4e07-87d3-46b2-b058-18e5f001fb22    Created invoice for billing month 2026-05       2026-05-02 17:27:43.224915
1c72b606-72d6-4b2f-afa0-dbcbd4e953ef    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 2ebdf2f0-4110-4216-b91c-5ae5a8e811e7    \N      2026-05-04 04:44:44.153852
e74356e7-0282-4c75-ab0c-7fd3457b7eba    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae rollback_invoice        invoice 50f15835-253c-4d88-9358-02769da532ba    \N      2026-05-04 04:45:31.283771
2d19cf20-dd4b-4b28-81fe-390a32b811f4    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_invoice  invoice 7e1ceb04-00bd-4d52-b0f6-668d6eac094f    Created invoice for billing month 2026-05       2026-05-04 04:45:50.452099
23c4cce0-6730-42a8-bed7-4deb3a4a3ab1    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_billing_month   monthly_billing_approval        a7e0c5db-4c95-438e-8869-3a543606f695    STORES approved for 2026-04     2026-05-04 07:30:20.454524
f4f902af-535b-4a31-b607-5c97dc6a50e2    853acd7c-4759-4213-ace1-b7da16385a52    admin   approve_billing_month   monthly_billing_approval        db8f6385-ca75-4c30-8e40-944e2a71109e    VET approved for 2026-04        2026-05-04 07:30:22.839507
bc9b2611-c795-45db-bcc3-8f0ea2782027    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    e6594f6e-5c87-4a9a-8178-02ddc964be1c    Price changed to 100 for item ClinicMAT- Spinal needle 18G × 10 inch    2026-05-04 10:15:18.756462
371cfe16-1441-4274-a4d6-7e36aa6f84c3    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    e6594f6e-5c87-4a9a-8178-02ddc964be1c    Price changed to 90 for item ClinicMAT- Spinal needle 18G × 10 inch     2026-05-04 10:15:26.346293
eb525536-1a95-4710-8a29-43ed666cbce7    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 62181d25-a893-4990-916c-ac116c446b55    \N      2026-05-04 10:16:50.787406
35c2f856-dc10-40ca-b521-83e27a8ec480    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element f561357a-0d6d-4bb4-bb5d-276bd0fa7bd9    \N      2026-05-04 10:16:51.320075
e59bce7d-42be-4503-b66f-29ee6dc9d94b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2352a6c0-162e-41ac-bb96-d24e87938755    \N      2026-05-04 10:16:51.718584
2eb3e46b-3024-4e3e-a980-9ef11b54b652    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 0527605f-05b5-414b-9279-aa21c89a9269    \N      2026-05-04 10:16:52.112141
17aa98ef-0765-4416-a538-2490c8b20629    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 16c8b47f-75cf-41db-8383-513ab2b6582c    \N      2026-05-04 10:16:52.51831
b0200a21-a8d9-4061-8ef7-5497e5c05635    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 8a8437f0-68a2-4651-a966-07706100fbb2    \N      2026-05-04 10:16:52.933002
daefff8a-e7aa-4909-b353-d25479ddcdf8    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 6de9c2a9-0e2d-4cf1-9a5d-87a690739776    \N      2026-05-04 10:16:53.337362
5089194d-885e-467a-ad33-b8cae74fafb9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element f226bab3-afea-4c27-888f-913daccbd34e    \N      2026-05-04 10:16:53.779066
4e61fe34-45cd-43e3-a917-5e88258cee5a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 8dafc397-8180-47c8-9fa4-eae19e611a07    \N      2026-05-04 10:26:24.570984
0431a307-f21f-475f-b013-8e4df8c6e6cb    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element a81cb9b5-46fe-4c98-b0fb-8748e7066227    \N      2026-05-04 10:26:25.776099
a92090a1-94bc-4a91-b28a-dec7302b48b8    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element c5129a13-ac29-4c4f-89d4-9c7c1bdedd3d    \N      2026-05-04 10:27:12.696114
698f1a8a-75d3-4cdd-99dc-6eb610b4833b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b233b7d2-c865-471f-826f-b2ed8f7ef70c    \N      2026-05-04 10:27:13.109543
e193ad93-38ff-4f0d-b0c6-dd768a67ad11    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 56a074f1-892d-497a-971a-9278ae36f339    \N      2026-05-04 10:29:54.419961
37a5d0fb-6c9d-484d-ae6e-55746f892cf5    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    db25e6c6-88ec-4341-91dd-1d61e018244b    Price changed to 18 for item ClinicMAT -Fucidin Ointment 15g    2026-05-05 10:26:25.679485
4e5bbb62-2cc3-4c8d-90ca-d125e9378de1    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    dc3474e9-1bda-44df-9324-49f155bba5c6    Price changed to 30 for item ClinicMAT -Zinc Oxide Cream        2026-05-05 10:31:47.839156
3ec681d4-90dd-46f2-b853-40bd2e2ab7bb    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 32c3ecbd-ed85-4512-ac65-4981e4fc145f    \N      2026-05-05 10:32:16.728252
81704d07-550e-4ac3-9247-08a5757e480d    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element d2100b0a-a5ee-4f57-8900-66258ac1fd64    \N      2026-05-05 10:32:17.162328
714ab297-b293-46ba-b50b-548333eb80c0    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    5b2c8e4b-f4b2-4c45-aa3c-4f971a2a7b69    Price changed to 180 for item ClinicSRV -Nerve Block - Abaxial Sesamoid 2026-05-05 13:55:01.042991
51d95c9c-a1b1-472e-9a84-bab09bb464de    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    f1567c9c-be47-4be0-9005-2bbd561bf765    Price changed to 180 for item ClinicSRV -Nerve Block - Palmar Digital Nerve Block       2026-05-05 13:55:21.693763
37177c83-e41d-4537-af77-6baf1c415903    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    2dbbcf5a-acc0-4e55-9d59-180ec55d3745    Price changed to 278 for item ClinicMAT -Mepivicaine (100ml bottle)     2026-05-05 13:57:58.703707
860d6a1e-b0df-4ec3-97bc-34c2839f0285    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    b9bb0433-85e7-4e32-b4fe-bc2fbc546754    Price changed to 400 for item ClinicMAT -Animalintex    2026-05-05 13:59:59.625127
567eef60-6f48-45ed-aed0-e5ec45925f5c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 819dd43f-92a0-408b-9b46-9043697e81aa    \N      2026-05-05 14:00:32.831657
f3897925-45b9-4b4e-84ba-281a19389289    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element ca72a355-73b0-4ca3-bbd5-bba99f217313    \N      2026-05-05 14:00:33.278102
9458d012-aa10-4073-8378-4d15fc9b583c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 66d43c7f-eb86-43bd-84c8-d6f0cbdef6a2    \N      2026-05-05 14:00:33.760766
daa92065-3177-4a61-bade-aade25042398    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 0a30b4ea-1350-4ab8-b501-93d367193b30    \N      2026-05-05 14:00:34.289476
bca93304-a0db-4ccb-936e-f107a644ab26    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 3c5bfd90-e4f3-4309-9897-2d307fd98ca9    \N      2026-05-05 14:00:34.69137
60ef052d-883d-452a-b158-944a25fde5f1    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 8c66e30c-6e39-4788-bcb6-988ca3fafa50    \N      2026-05-05 14:00:35.086315
a6f037f6-7aad-4e56-abf4-e519d4317b59    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 60cf298a-966a-4036-bbb2-900dc734628e    \N      2026-05-05 14:00:35.535793
88036440-e580-4902-9b57-a3d0a1b292e1    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_invoice  invoice 85bf1ea5-70de-441c-848c-01aaceaa2bcd    Created invoice for billing month 2026-04       2026-05-06 06:18:42.04091
698e6d44-6ef4-4a98-a9c5-9d35f69845b9    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae checkout_agreement      agreement       0bef9c96-2792-441d-80a2-6b292d33210a    Checkout agreement, end date: 2026-05-06        2026-05-06 09:33:17.696095
cbce59b5-8dc6-4041-b306-0eaec04393e0    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae checkout_agreement      agreement       c16b9e28-f638-4839-ab11-6d1d257e73f9    Checkout agreement, end date: 2026-05-06        2026-05-06 09:33:36.374893
b8106d51-7ba1-494e-b00b-8b86635e9770    853acd7c-4759-4213-ace1-b7da16385a52    admin   rollback_invoice        invoice 85bf1ea5-70de-441c-848c-01aaceaa2bcd    \N      2026-05-06 14:03:44.176993
277d6ae0-0de4-4a9c-be14-1ef86b661347    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    0c0d2601-f01e-45d4-b9c4-e7f10ad68792    Created user: hassan.khairy@adec.ae (role: FINANCE)     2026-05-07 06:03:21.31931
b9f6a18f-2802-40cd-89cb-a69f98d26547    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    b35649fd-0d77-4ea6-a6e6-3f913448911f    Price changed to 300 for item ClinicSRV -Joint Block/Medicate - Fetlock 2026-05-07 08:28:14.295872
c480150c-129c-4321-9edc-8453457f7d8a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    d09293ab-4fb8-470f-9df3-37087aea5212    Price changed to 350 for item ClinicMAT -Equinate Inj (12 x 2ml vial)   2026-05-07 08:32:04.883739
223c2d67-6a67-4422-8542-0888ca35cc54    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 4269bcbe-d30f-4535-94e5-c63373585e36    \N      2026-05-07 08:37:57.984208
f80b897e-aecd-45f6-ba0a-8140d0cc722d    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 8b6f6a80-f001-42ea-854c-4765212bf693    \N      2026-05-07 08:37:58.463868
ad87a093-45fe-4cbb-bc8f-5a18db924f30    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element d01758ea-ae5d-4a00-a144-35bff5eb7c53    \N      2026-05-07 08:37:58.93494
b10ce41b-9b8e-4cd2-b69b-f67706c7feda    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element db29253a-6bed-43b4-a2ce-a361dee95083    \N      2026-05-07 08:37:59.380057
a6e42df8-3459-4112-bfc4-bca560727748    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 05f8b202-941c-460c-b1bc-1e11101055fc    \N      2026-05-07 08:37:59.887431
feedd20a-d337-48f2-b6d0-2b377c2dae81    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element c33ec13e-1b39-4e50-a4aa-00f8bf5774bc    \N      2026-05-07 08:38:00.348932
f55de624-59e9-4cfa-82a4-4b304ba07cf8    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 260a575a-1ea9-44cb-a7df-8be61faa2d47    \N      2026-05-07 08:38:00.830769
f2a5f09e-a66f-4806-ad23-b67e432a4d31    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 37516455-76c4-4c84-a548-5c0a05af8092    \N      2026-05-07 08:38:01.460606
c556754e-134f-4a28-ac27-13a0074cfed8    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 0fe03167-625d-4838-b7f4-3193307c6822    \N      2026-05-07 08:38:01.897928
da846ee5-9e3b-4ecd-b32d-e1bebc6b4460    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 48c95499-834d-4edb-a2ce-9975acd1af3a    \N      2026-05-07 08:44:53.95721
66797ae8-87d2-463e-8b72-996b2df9bab9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 1b98dcee-5b37-4f28-9d59-3a80a93b6a40    \N      2026-05-07 08:45:01.754941
1e715c0c-07b0-4c43-a29e-b6c0119f968f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 5f02fd5e-9eed-4a52-bf88-645ab08a50de    \N      2026-05-07 08:45:07.976392
aa6f0692-71c9-446f-b21b-eaddf9a287e7    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b2d366de-e6a2-4389-ada3-bd7d9fe1049c    \N      2026-05-07 08:45:16.677093
43ba7c1e-dee2-4153-b2f3-23d3a43fe4da    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 06dcff75-3898-45a0-9972-f2e43eb3b4ef    \N      2026-05-07 08:45:25.501084
15303ded-1aa3-4bd0-a370-492541827dd0    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 8267c1a3-807b-4d0d-a01a-f1efbd0fc03e    \N      2026-05-07 08:45:32.261765
e9304f49-322b-4f6c-bda2-aae5ead10dfc    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 5ba4cac1-04f3-47bf-9950-f82989443228    \N      2026-05-07 08:45:46.180245
2b32ff58-7685-405e-b37f-eaba5a6be275    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b808478e-ab7b-489f-9392-a2f6e66f9b64    \N      2026-05-07 08:45:52.383276
642e5d3b-2f9b-4725-9772-bf09ba7518d9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element c61175f3-afb9-42f1-a66d-e6d0bc28da8d    \N      2026-05-07 08:45:59.909766
269d3ddc-33c9-4b8e-8cb6-9a27cd16b4bf    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element b2d366de-e6a2-4389-ada3-bd7d9fe1049c    \N      2026-05-07 08:46:23.360575
60aed87e-fc89-478a-9e18-824cc78b95b1    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    57429aed-2879-493d-b541-71347a13266a    Price changed to 150 for item ClinicMAT- Proteqflu- TE-FL1DOS   2026-05-07 08:48:42.249443
0b25077e-43cd-496c-97a7-508061a02505    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 4b29c8d2-cda4-4f08-9774-1e01dfe44b33    \N      2026-05-07 08:48:58.887459
8b4cea6a-ee19-424d-a360-1a79014d7099    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 4b29c8d2-cda4-4f08-9774-1e01dfe44b33    \N      2026-05-07 08:49:26.997218
22d1a728-d567-4612-9ac0-cea6b6bfa713    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 42f4315a-95c5-48cc-88f5-cf5d12df738d    \N      2026-05-07 08:49:50.429937
4b8d9de2-651b-4f9c-956c-3741feffe6d2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 8f66102a-2ec0-4f27-bd2d-aeffefae4c4e    \N      2026-05-07 08:50:08.87787
467db5a1-2713-4168-9c62-c7dfea025c92    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 94bc17cc-5877-4035-a107-6fab2cb257e9    \N      2026-05-07 08:50:43.713546
e34511f4-133c-4e9e-b4eb-8f2ead919816    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element c02cf429-c65e-4792-8db0-8fcb0c820e71    \N      2026-05-07 08:50:44.171027
f893f55d-7ae6-4d23-aa52-d76c8878ab32    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 92e3bfc0-2f38-4c9c-8bee-d77a20d3facd    \N      2026-05-07 08:53:03.868424
b52eb9bd-b1ab-44a6-9561-02985ddedb91    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 32c3ecbd-ed85-4512-ac65-4981e4fc145f    \N      2026-05-07 08:54:38.326305
f6618883-8730-437f-bef4-6d77cd425d49    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    db25e6c6-88ec-4341-91dd-1d61e018244b    Price changed to 24.24 for item ClinicMAT -Fucidin Ointment 15g 2026-05-07 08:55:00.925592
91f06134-279e-4dab-9791-ea6d58403e5d    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b8a5ccb6-22c9-4aa6-ae47-9ab476063982    \N      2026-05-07 08:55:15.702049
f1e29f8c-8141-4ec8-b169-3600a8de7546    853acd7c-4759-4213-ace1-b7da16385a52    admin   change_item_price       item    c52845a1-6209-4f20-a232-2e83c2c522ac    Price changed to 600 for item ClinicMAT - Meloxicam Inj 100 ml  2026-05-08 07:45:56.356453
c09f2908-491f-44bd-817c-89c4722f78ee    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    05e28e05-df88-4bd8-b38b-5fcad1a689be    Price changed to 200 for item ClinicSRV -Consultation Short     2026-05-08 10:21:07.877487
6d60d68a-959c-4016-8e2d-799b3a5fbd4b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    cb849f39-2cb0-4c35-a03c-953402a8132d    Price changed to 400 for item ClinicSRV -Shock Wave Therapy Per Session 2026-05-08 10:22:42.935154
d6f5ba5b-fdd3-4f10-b001-3ee4a8dd6482    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 4b3c2566-e6af-4399-8b4a-33c1c2857db5    \N      2026-05-08 10:23:04.370729
4300a8bf-f68b-4eb8-8e8c-fa53239f8cd2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element f4f01340-3b91-432e-8d67-b575bce3a2b3    \N      2026-05-08 10:23:04.798787
a0ce4f9f-9e6e-4345-855c-de83cb8baae5    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    Price changed to 300 for item ClinicSRV -Consultation - Standard        2026-05-08 11:38:11.49347
8b18027b-859e-4c69-8a65-0f06ff8ed0ce    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 2827b892-080a-4891-a76d-efb5d96ce2f6    \N      2026-05-08 11:41:55.076046
e4aeefa9-59df-4e4e-986d-528c7acb6a9b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    cc0a7c79-e7b4-4145-a0de-91f9e9e8deca    Price changed to 200 for item ClinicSRV -Nasogastric Tubing     2026-05-08 11:42:23.127391
09631555-afed-4ccb-8878-fa744d133976    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 308402bc-a5c4-43c7-94b8-3fc62f802474    \N      2026-05-08 11:42:39.087622
a8001bf7-000d-44b8-b41f-948de23aeaab    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    2e06201f-ef06-4cdb-aafe-2a5c8efaa28d    Price changed to 340 for item ClinicMAT- Invokana 300 mg        2026-05-08 13:25:07.178819
32060f66-7d0e-4a45-84a2-92893f02275a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element bf684968-ba71-4b8d-a819-ac210bd99016    \N      2026-05-08 13:25:19.353577
0f1cef7c-7db9-424b-8e01-917ee1a181d4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 52b2da9b-4213-4f7e-9e3c-35a7dfb42773    \N      2026-05-10 13:44:01.672805
6f009617-2da5-4eee-aed5-396205f808ff    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element df0c49a7-81f9-4ee2-9580-160ef19dba2d    \N      2026-05-10 13:44:18.271385
ee9e73fc-e500-4f14-b5b1-6b3f784600c0    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b6398d33-c6ee-47e8-940a-37fa5b18f435    \N      2026-05-10 13:45:17.633147
ffb0d191-0e12-45e3-b308-16486a47eca1    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 6b34a8fc-c259-4166-8805-f6ec3ef52e01    \N      2026-05-10 13:45:18.113015
5470abdf-a4cd-44a9-9b15-bcc4aac4c9e1    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element b6398d33-c6ee-47e8-940a-37fa5b18f435    \N      2026-05-10 13:46:29.211765
939f72c9-75d3-4a6e-9920-a5cc212e8bb2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element dfaa3bbb-0a06-4d39-b98f-3619d4f20909    \N      2026-05-10 13:47:16.239475
d5c31b5f-3498-4c6d-8bbc-37bd36546781    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    07e360bc-92f2-4eac-beb4-0cac5e8b0101    Price changed to 230 for item ClinicMAT - Dexa 5% Inj   2026-05-10 13:50:52.596253
ea6a887c-3bb9-4142-962e-438bb8610378    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    07e360bc-92f2-4eac-beb4-0cac5e8b0101    Price changed to 103.95 for item ClinicMAT - Dexa 5% Inj        2026-05-10 13:51:42.653657
e111e2ce-a155-4086-8c85-b989f6484e86    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    dae09228-c921-4b5d-9e6c-87e5a2daea20    Price changed to 450 for item ClinicMAT -Sarapin        2026-05-10 13:55:31.0579
83c6a2f0-88a2-4c5e-8e5b-6fb4156ea00b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b37f73a6-c8a7-4f21-a725-3a137bba783e    \N      2026-05-10 13:56:55.09364
3df5fb9c-c0c2-430a-9bb4-f54013594c8f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 972ffb45-05ff-4642-a5b7-08dce925224c    \N      2026-05-10 13:56:55.826158
9365b4fa-8bbd-4e88-b22a-ef418d238cd1    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    bebd5b6a-0f1e-47ad-a6f9-cf22e0aae3aa    Created user: saleh.shaaban@adec.ae (role: FINANCE)     2026-05-11 07:17:52.111788
306f5a4a-d479-472f-b44f-6f4f969e211d    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    49fa781f-4c51-4f1f-9fd5-d99eed079912    Created user: hagar.shehab@adec.ae (role: FINANCE)      2026-05-11 07:39:01.916657
ff6227a8-2e59-4874-8901-3fb34d048250    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 1572b631-38cc-476d-9419-79b75a2b317a    \N      2026-05-12 07:52:39.799154
bd1b79ce-e23c-4ad1-b898-24299f0c7eb1    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 85453fa9-ec49-4c35-9692-7e1cbb7f7da8    \N      2026-05-12 08:18:05.555842
9fa63e03-e1da-4649-ac60-8e93a94c7c06    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element cf42778e-81d1-4ff7-9ce7-6a1ff96d03ad    \N      2026-05-12 08:19:01.838075
422d4556-499e-4b34-bf3c-1c7100b6e776    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2e0e761f-1797-4996-b738-883445131cbc    \N      2026-05-12 08:20:25.73212
42d214da-82c5-4caa-90b4-46634adb9631    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2590cc1f-3ed0-42cc-8790-db594cc5bcd2    \N      2026-05-12 08:20:50.310864
4e9bc5af-c371-4b7a-a38e-de940ced3a94    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    2ff1dc27-1d89-451d-9e33-deda80c3f31c    Price changed to 350 for item ClinicSRV -Visit Fee Standard     2026-05-12 08:25:52.030936
61a26b09-6bac-4d92-bbbc-66ec40a543fe    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 750d6891-4a4b-4740-8673-e6611ba5f38d    \N      2026-05-12 08:27:24.435947
ba04bcca-e16f-46c3-9ba4-db25f9f0cfc3    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 236b0d8c-9dec-427e-aa0d-45de03306a9a    \N      2026-05-12 08:27:24.890668
722eba28-f109-4a27-ab39-b628911acafb    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 63970c98-02c4-4d32-8b5e-a960f4e7eea7    \N      2026-05-12 08:27:25.304133
b6e9ea1e-8fc0-4c25-9315-40217dc3f328    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 3223080e-1279-4c9f-a8e7-07ce8b9faaec    \N      2026-05-12 08:27:25.764734
8649ce3f-e481-41bd-ba10-5d0c1732dcd6    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element d807249d-b495-4759-aa20-80fde2c178a1    \N      2026-05-12 08:27:26.197753
a4f9b0a3-3735-4ad7-ad14-7520334e914a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 910bd7dc-0963-4512-a99c-bb346694acc4    \N      2026-05-12 08:53:02.200918
9f34f706-f349-4549-a94d-f435120f31d3    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element ac3921b4-44c5-49ce-b8ec-d29c8ee39a99    \N      2026-05-12 08:55:48.621252
d560a36f-3932-43b0-ab86-4079b916db6d    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b1d33c4a-3d62-4bb7-a3de-63dcc332c1a8    \N      2026-05-12 08:56:45.757552
25b9f046-cfbc-417a-8b07-6a1b7f04fa49    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b43e2200-5d1f-46ed-a18c-4d50851d3194    \N      2026-05-12 08:57:20.86839
c0c43538-732b-4302-b312-83e968778dcf    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element dfaa3bbb-0a06-4d39-b98f-3619d4f20909    \N      2026-05-12 08:57:48.619768
fb2f02f6-0edd-4209-ad88-05215fd69458    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 6b34a8fc-c259-4166-8805-f6ec3ef52e01    \N      2026-05-12 08:57:57.73564
24f232e8-03ec-4de3-af6b-f4497e42eb4b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element d7ff3fc3-ecef-41eb-93f3-f23ad7b0f04f    \N      2026-05-12 08:58:38.176173
2fcb8483-7c6b-448c-945c-59935297fc71    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 09d69775-9783-469e-8e6f-fb5e6d63c738    \N      2026-05-12 09:15:58.680956
f867199c-e6eb-436e-b40c-4c75a7aee5e6    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 6554e95e-d21a-4668-bc1b-5e687d071967    \N      2026-05-12 09:18:11.505961
2f5c88b5-6bd6-43e6-9300-62db4da3b006    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 78e4c3d1-8bc6-45ca-bcca-c05b9243ed16    \N      2026-05-12 09:18:35.856099
db88a751-95ad-4b86-98ce-01ac7e5dd7b6    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    sync_netsuite_items     items   bulk    created=9 updated=1752 unchanged=398 total=2159 2026-05-12 09:44:43.386937
8a8d0f44-7163-4f60-a96c-5b3877aef46e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    sync_netsuite_items     items   bulk    created=0 updated=0 unchanged=2159 total=2159   2026-05-12 09:45:24.519998
326ebe2a-b0a5-4153-82f8-c68343824091    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 09581903-9c6f-47c2-811c-f32266a93058    \N      2026-05-12 09:47:33.504875
839308a5-3a34-42da-86ad-c74096985ef7    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 14c0f139-51d0-49f4-aa2e-85aafaa4cb78    \N      2026-05-12 09:47:33.96699
8aa97916-e9cc-463e-8724-fc871afeb0a7    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 61d4fb61-3330-47d9-acc4-19fd3b625ba0    \N      2026-05-12 09:47:34.412062
70a87e55-729b-4ca7-ad19-49956fe94474    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 259fdc80-cf74-499a-a4a8-9d7f7efb05df    \N      2026-05-12 09:48:13.835601
c2c12c36-dc73-497c-a6f8-7a06b844ea62    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    17d4e825-c298-441e-a85c-c5ff6cbd15a4    Price changed to 140 for item ClinicMAT - Sed Ace Gel 30ml      2026-05-12 09:52:38.178907
07e7f619-441a-41ad-86d4-efc5f5b3e077    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element a691e545-75b4-4a66-969c-c075390e07e1    \N      2026-05-12 09:53:07.728535
72e72a13-91fc-4860-bdda-989449833a6f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element fe97946d-ae7a-4dba-988e-4371313bd0f9    \N      2026-05-12 09:53:08.158109
761230b4-d589-42c8-872b-47b26691d810    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element fd5f15ca-1b09-4bf8-aa7f-12b7b28b2825    \N      2026-05-12 09:53:08.697132
469ff402-c81a-4486-935e-317c8ad3f4b4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    sync_netsuite_items     items   bulk    created=0 updated=1 unchanged=2158 total=2159   2026-05-12 10:34:47.26967
8a6bd93d-286f-4fc2-afa8-f5db4160a380    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    sync_netsuite_items     items   bulk    created=0 updated=0 unchanged=2159 total=2159   2026-05-12 10:51:08.063361
5b48b3a6-b04c-4c49-a8be-33b962a6a207    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    sync_netsuite_items     items   bulk    created=0 updated=0 unchanged=2159 total=2159   2026-05-12 13:58:05.753458
723b51a1-9252-4fa6-a898-208ab2466b1a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element dfb01460-5cfa-4f46-96cc-fa4fc0ccac7d    \N      2026-05-12 17:16:59.593102
970e8383-f550-4637-b008-6ee751d2fd72    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element dfb01460-5cfa-4f46-96cc-fa4fc0ccac7d    \N      2026-05-12 17:17:50.216575
099dc4ca-fb6e-4f30-815d-ddb28674d95c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element f4f01340-3b91-432e-8d67-b575bce3a2b3    \N      2026-05-12 17:28:32.370059
c7b68ef1-2ab4-460b-82ee-45a991cd10de    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 8c66e30c-6e39-4788-bcb6-988ca3fafa50    \N      2026-05-12 17:30:58.654661
97a8d017-ef01-4339-8401-00d3242b2117    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 0a30b4ea-1350-4ab8-b501-93d367193b30    \N      2026-05-12 17:31:40.867691
97ef0d65-8559-4295-83f6-bb1c12f07f31    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 60cf298a-966a-4036-bbb2-900dc734628e    \N      2026-05-12 17:32:59.24709
6bdee49b-7e5d-4bab-8e37-4c3fcf6f6ec6    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element f226bab3-afea-4c27-888f-913daccbd34e    \N      2026-05-12 17:33:42.276931
3e969a8a-164a-41de-9980-b01aa32d496e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 20cb0c32-2ad6-4c9b-85db-343a2908b12b    \N      2026-05-12 17:34:34.163749
cca9c035-e2b2-4936-8fd1-ea6a388df1db    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 33f21ba8-b10e-4842-aa3f-c2dd33d771f0    \N      2026-05-12 17:35:16.301811
6ccdf9dc-c744-4392-834f-a2730cf4ad49    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 76640e02-6678-4579-9f18-4dd45bac046b    \N      2026-05-12 17:36:00.392304
2c65acb6-2921-4d63-ac0e-f93e95475624    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 43388791-9bd4-4dad-a024-49150d452f16    \N      2026-05-12 17:36:22.923556
600ca4e0-b638-4dff-94b2-c5e92b20cbdf    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 60e128f7-1f36-40b5-a357-a39c811f665e    \N      2026-05-12 17:37:45.973776
8ae0b40e-c51f-418a-8b33-7d88dd7f2517    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 3223080e-1279-4c9f-a8e7-07ce8b9faaec    \N      2026-05-12 17:38:36.941946
0d4a5e5b-ea6e-4bd6-8445-4aa4f4f7fef3    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element d807249d-b495-4759-aa20-80fde2c178a1    \N      2026-05-12 17:38:45.776094
276d6972-670b-4e36-a0a5-88ce4abfe5ae    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 7332e8e1-f3d0-41ef-8c8d-09995bba0e21    \N      2026-05-12 17:39:30.324923
9c3f7770-b213-4e1b-9a2d-3a324d806258    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 56a074f1-892d-497a-971a-9278ae36f339    \N      2026-05-12 17:40:23.914483
f360edc8-47df-492b-90f9-a5e0e48c7ba9    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 6de9c2a9-0e2d-4cf1-9a5d-87a690739776    \N      2026-05-12 17:41:21.943008
82dbe1f1-7265-4d56-997a-a03c2f3064bb    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element ffe8379d-b62c-4201-9736-397a8ed891fe    \N      2026-05-12 17:42:11.523609
0967ef88-cfb9-4cf1-a9b1-10ee4227c10e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    update_billing_element  billing_element 16ef95cc-6744-4162-8a10-132be7eb52d9    \N      2026-05-12 17:47:50.295524
6a5d3880-f0c2-4626-978d-7ad3f217ccdf    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2beff791-4925-4a03-b10e-ec49e76960f1    \N      2026-05-13 08:55:54.007897
742f52ef-806e-4f1b-b1fb-15e5cb24df3f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element de8a6831-eae8-437e-9836-3a28a0b56c4f    \N      2026-05-13 08:55:54.502644
e62cf8e3-c7bb-4c1e-8705-c979e8f3e1fd    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 06038efc-2047-4be2-abf6-92cec75047e3    \N      2026-05-13 08:55:55.067818
1d3ba1ad-3451-4f98-9cb1-0dc41f22f973    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 1397f247-aeed-46ad-84d3-206ddb3e4231    \N      2026-05-13 08:56:38.403007
384eb650-6617-4e90-8a1e-6be72a03dbe3    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 002adfe9-8ee5-41d0-8822-a8d81271526a    \N      2026-05-13 08:56:38.882496
a34c99eb-5025-4641-8935-954223dd336f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element e37aa1ee-8892-4b5a-acbf-18a1a5c7ba85    \N      2026-05-13 08:56:39.345971
72e64317-9841-465b-9693-ddd2b097588f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element fe46cec2-6e85-4361-9550-43386afca6aa    \N      2026-05-13 08:57:30.261434
2a8c4be7-44ae-4206-907c-e440ebe67648    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 81bcc385-7d73-441b-8686-35209c77e990    \N      2026-05-13 08:57:30.771631
6a0d4e1f-0a44-4ddb-b3bc-e59bbab2fa4e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element a6cdaf0f-222c-4586-aac9-27b6148b8afe    \N      2026-05-13 08:57:31.273782
fbb1b933-45cd-4fb2-8c6f-89bf23a3aba9    853acd7c-4759-4213-ace1-b7da16385a52    admin   reset_password  user    de0adb89-60c5-4188-871d-0a14bb226223    Reset password for user 2026-05-13 10:02:46.232158
e0dd650e-c9ea-4844-80d4-e941af0c7a38    853acd7c-4759-4213-ace1-b7da16385a52    admin   update_user     user    de0adb89-60c5-4188-871d-0a14bb226223    Updated user role to: ADMIN     2026-05-13 10:02:46.449239
8a0fd345-9a5a-43db-b9c7-1d30684a35e3    853acd7c-4759-4213-ace1-b7da16385a52    admin   reset_password  user    853acd7c-4759-4213-ace1-b7da16385a52    Reset password for user 2026-05-13 10:03:05.154839
7a53c0b5-2a9f-4795-81e2-eabc50b85d38    853acd7c-4759-4213-ace1-b7da16385a52    admin   update_user     user    853acd7c-4759-4213-ace1-b7da16385a52    Updated user role to: ADMIN     2026-05-13 10:03:05.379144
7b1e6118-7c6e-4df1-9a7c-dd94c30fd655    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    5f2a1d87-9068-4f91-bf5b-34c55b5b9fa4    Created user: radhakrishnan@adec.ae (role: ADMIN)       2026-05-13 10:10:40.34826
09bdc721-5943-4cae-afa5-3dbe7787dbda    853acd7c-4759-4213-ace1-b7da16385a52    admin   create_user     user    03a8b97a-eb58-42ad-bbeb-9ebe5de77abf    Created user: patrik.wagner@adec.ae (role: ADMIN)       2026-05-13 10:39:55.18282
5f6d90f1-540c-47b9-a883-c27cbe917efe    853acd7c-4759-4213-ace1-b7da16385a52    admin   sync_netsuite_items     items   bulk    created=0 updated=1 unchanged=2158 total=2159   2026-05-13 11:08:17.955573
2646090c-0649-4bb9-856e-35691f20cd85    853acd7c-4759-4213-ace1-b7da16385a52    admin   sync_netsuite_items     items   bulk    created=0 updated=0 unchanged=2159 total=2159   2026-05-13 11:09:37.498608
fcb80efb-aabf-4ea6-95e2-e8183e40ded6    853acd7c-4759-4213-ace1-b7da16385a52    admin   sync_netsuite_items     items   bulk    created=0 updated=0 unchanged=2159 total=2159   2026-05-13 11:18:03.034557
4952ee32-bc87-4c87-a631-f9c9d0b913a6    853acd7c-4759-4213-ace1-b7da16385a52    admin   sync_netsuite_customers customers       bulk    created=0 unchanged=2 total=2 skipped=0 2026-05-14 06:57:37.034107
dca90ca6-f00e-42bf-af3a-b6c8e1efd4bf    853acd7c-4759-4213-ace1-b7da16385a52    admin   sync_netsuite_items     items   bulk    created=0 updated=1 unchanged=2158 total=2159   2026-05-14 06:57:52.048166
f4507b23-f0fb-495a-8405-b39bf9b70f2c    853acd7c-4759-4213-ace1-b7da16385a52    admin   sync_netsuite_items     items   bulk    created=0 updated=0 unchanged=2159 total=2159   2026-05-14 07:16:29.679118
dd4e0847-8c7b-44d6-9bc1-95d873d5f5b9    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_agreement        agreement       68358b63-163c-4e04-89b4-0b875713c96d    Created agreement: LA-2026-8428 2026-05-14 11:19:19.442849
28f1dd16-c7b0-4af0-833f-ef2f1b6b7359    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    96f4a9ae-e972-4dee-bd40-8e8223f2d4c6    Price changed to 300 for item ClinicSRV -Consultation - Colic (Clinical Exam)   2026-05-17 17:33:38.616008
a4eb53ee-8a00-4dcf-8dc1-705e2af8741e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 15270554-114f-479c-88b6-14d391e65a06    \N      2026-05-17 17:39:40.562951
60e092ea-8959-48f7-ad48-74cbfc47c4c3    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 346bac65-ee5a-4573-9beb-ae08bec1cf27    \N      2026-05-17 17:39:41.105384
d9efcb18-5644-4c09-b977-b7b08acf97ba    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 7e275145-5d63-4177-b113-08329e2da0d4    \N      2026-05-17 17:39:41.612201
0a7431df-0cb7-41e3-8178-623ba0c998ef    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element e29073b6-2684-443a-bf4a-e24ab791a907    \N      2026-05-17 17:39:42.124496
cc112669-b18d-4e70-b16f-76bc5745b36a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 172e9f10-32cd-4229-85de-73f3fb93331d    \N      2026-05-17 17:39:42.644021
32ae1669-1be2-4b18-a139-643f25378d2e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element ec40dc43-99a0-4afd-8051-79fec939d593    \N      2026-05-17 17:39:43.151751
c68413ef-85f0-48d6-9378-0262188b3a4c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 726cacda-70a6-440a-883b-6822b8180a97    \N      2026-05-17 17:39:43.667564
a6162793-0254-453d-bb33-16aa3ab1f5bb    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 24c29d58-1d55-4e2d-9c7d-3032ec8493f6    \N      2026-05-17 17:39:44.150142
07a9bbcc-5409-425d-9851-54b3fbab4fb8    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element cf820dd4-11a1-481a-9f3a-5b6520b6817a    \N      2026-05-17 17:39:44.686873
c2a757c9-ad1d-4ec3-9245-865678383d91    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element cff21fa4-d1cb-468c-b095-cec15cb334df    \N      2026-05-17 17:39:45.190205
2bb861aa-07ab-44a7-92d5-28243294f797    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 8f8d1200-f8fb-4edb-812c-8493acd3a054    \N      2026-05-17 17:39:45.711935
e9aa3cfb-eddb-4339-8ba6-bb6ad980565b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element ce7d9c80-859f-4da8-8a97-473d381eca1d    \N      2026-05-17 17:39:46.209801
988d4c5d-4387-4086-8961-38d88383503c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 86024855-58f3-4010-880e-8783d07765dd    \N      2026-05-17 17:39:46.701645
0df19680-d481-4389-819d-71aacc380e61    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2fb86123-075f-471d-aa90-75efe361a8fa    \N      2026-05-17 17:39:47.202203
2d8f686a-b18c-43bf-a947-18127e7c6d12    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 3299a96e-fa4a-4cd5-bcfc-e2b07e5d3d79    \N      2026-05-17 17:39:47.682212
0d227bd9-6843-4a94-82c3-087736ef1949    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 506fd77e-8fe0-42f0-8ed6-18c1705af2f0    \N      2026-05-17 17:39:48.171406
882e4103-e406-4db0-98d6-ff4769e2fb56    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b4122884-0ba8-43c2-bdf9-b8ce655b8499    \N      2026-05-17 17:39:48.650978
cab37220-782f-49a0-95a8-17d4feb85da1    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element e5578c23-e46c-458d-8491-84f2de9aac14    \N      2026-05-17 17:42:06.58418
8ea874d7-0809-4df1-a208-c33d78446cc9    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 8fdbfc99-7661-4d4b-b2ae-d134883295dd    \N      2026-05-19 06:02:10.148019
2df0635d-b531-4b39-824a-ed2bc6fefc48    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element ef8c523a-3be6-4a52-8b16-e35056bb5cf7    \N      2026-05-19 06:03:00.056942
22dbdab0-a922-4ed4-9af7-6f34ab25ac13    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 8b488da3-4be9-4b9f-a2da-0f592b20e36d    \N      2026-05-19 06:03:23.376471
c6720ce1-ac4b-40bd-bad5-556c976b4588    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element a7579019-9e93-431b-8744-33f53c46893a    \N      2026-05-19 06:03:59.157297
c6e91012-0402-4860-a169-21b5b64c3398    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element 8fdbfc99-7661-4d4b-b2ae-d134883295dd    \N      2026-05-19 06:04:17.183602
c0f59123-02b0-438c-882c-adc074de2f4a    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element ef8c523a-3be6-4a52-8b16-e35056bb5cf7    \N      2026-05-19 06:04:28.521873
e2acb0a6-03a9-4ccc-8f9c-283944a0a26a    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element adfaff43-f822-4cf9-9e03-d62a0071a716    \N      2026-05-19 06:04:50.02204
1cc2c33e-fc7c-4a4b-a8d8-e2a4a79b7db1    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 80e2cf50-10e7-403a-96b4-ea393642787b    \N      2026-05-19 06:05:12.093374
528381de-423c-4037-9ec0-f21481374a9a    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae delete_billing_element  billing_element 8b488da3-4be9-4b9f-a2da-0f592b20e36d    \N      2026-05-19 06:05:49.598803
3304510b-8e3c-4f8b-920f-5922fcebe05a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    a46629db-843b-46b3-bd1f-c786a900f21e    Price changed to 300 for item ClinicMAT -Engemycin 10%  2026-05-19 07:26:55.324436
a641af0f-8140-4cad-8cf8-f7a886c590a4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    718bbe4d-526c-4be9-a0d8-b25eda4df34f    Price changed to 180 for item ClinicSRV -Apply Poultice 2026-05-19 07:28:03.647015
933f1086-8c82-4c9c-9301-7ce09de4827c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element a72797d4-9c4d-4403-bba7-a7bc2fc4ce20    \N      2026-05-19 07:29:32.476427
c034070d-42fd-4abf-ba4b-747b5ff9b842    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element bd748caf-ef94-4e00-9bdd-1b8b28078aea    \N      2026-05-19 07:29:32.991934
48d3ed20-fee1-4629-b3a1-8edd4795afcb    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element c6dc662b-5d94-4693-9bc0-b23d903b04be    \N      2026-05-19 07:29:33.613848
1abbf05a-ccca-437c-98c4-24b2ffaf169e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element daa2e302-d450-4f72-9471-aa43580bd915    \N      2026-05-19 07:29:34.122226
4bdda62f-e578-44bd-b938-75b4dd75ba74    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 4812d35f-344a-4165-9a9e-c36983bd9e54    \N      2026-05-19 07:29:34.627961
ea7400e9-815c-4518-8de4-7d859ca09a9e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 5c383259-ec32-43da-9383-0296e05aff82    \N      2026-05-19 07:29:35.184402
5a535b91-a278-4da2-ab9f-38676300b3ef    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 78d6d0c0-3735-4ff4-b1bd-283989863674    \N      2026-05-19 07:30:01.086134
ffe3f661-07c6-4ddc-b35e-3a67e491a5de    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 3c0e7bd5-9639-4e31-b20b-d62d731d30b1    \N      2026-05-19 07:30:01.562357
4d1676f3-2089-4e61-a94a-5229a2a81749    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 554c615c-1ed9-46be-b32f-fad0cf8d60d4    \N      2026-05-19 07:30:31.569221
7e043d29-6e5c-4523-b265-dbe21455b627    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2f0dee78-5d26-4b6d-973b-578715529452    \N      2026-05-19 07:30:32.009392
24cf44ff-ef02-47d7-9f4d-781132679679    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b10f6e42-df9c-48ea-b8b4-beb02fe727b9    \N      2026-05-19 07:30:32.482672
d670c624-4e61-4129-bbaf-37af3318b30d    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element bdbbc451-5818-4e42-a344-d373ccf5f712    \N      2026-05-19 07:36:44.041907
0fbd2195-50c6-4e73-9642-2e1957c9a865    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 4a6105a8-adea-4b74-a1a3-ee5f1f7ae101    \N      2026-05-19 07:37:03.072887
97672fe6-6a47-48ce-84ab-438f39c9f3c4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    6925ceb6-8f53-4e2b-b1f1-76924af14ef9    Price changed to 862.50 for item ClinicMAT -Ovu-Mate Oral Solution 1Ltr 2026-05-19 07:51:46.775695
906bb8af-1e58-42b9-82f6-0896b7ce0068    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 826373fc-1b4d-43e7-aa88-23e6e82b24dd    \N      2026-05-19 07:51:53.485356
abb8f050-fa4b-4bc4-869b-29b4e2a5a111    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element e1437e2b-ff81-4f65-8a1b-17601c673b34    \N      2026-05-19 07:56:39.961257
f5e91034-abbe-4975-ba00-e19dd063af27    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 48497c77-2eb7-4d25-8b7f-7545a22d1605    \N      2026-05-20 06:57:10.754957
b5adf061-4de2-4c08-a245-d727e930d366    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 4038cbbe-4efc-40e4-b5ed-03d21e8aa2dc    \N      2026-05-20 06:57:11.27338
5dd71029-ecde-4b94-ae82-98c85935bea1    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element f795d29b-2f57-42e8-ab76-5f062fa55d13    \N      2026-05-20 06:57:11.741861
d5b56a17-b4d8-4851-ad84-118a153ae528    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 54dac16f-f213-409a-adb7-6df37f527621    \N      2026-05-20 06:57:12.266137
bac77598-ed71-4c4d-8f72-8affed3a72e3    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element f42768fe-8743-4cd3-9c58-0f25c27627bd    \N      2026-05-20 07:05:59.010172
7a6d28e8-55bf-4e1b-9fab-db66c970ec76    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 62d4529e-5d7b-45ca-85bb-12c46baa53f4    \N      2026-05-20 07:05:59.482536
6d97f360-c001-4b71-bd25-ce31c8345c24    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 6be3d716-a2e6-4bd5-b9f8-f4eb0b8b4c0a    \N      2026-05-20 07:06:33.472179
2912fb95-8de5-48dd-ac93-c7104a36dea0    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 0d8bd4c9-4957-47b8-a458-e2381de0d691    \N      2026-05-30 04:12:52.76299
769cf8ec-c5f7-4d04-be02-099467dc95e0    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 825a9d5a-4418-46bc-b919-cbc2c6f9856d    \N      2026-05-30 04:13:17.780823
1c110520-9e49-494e-8e88-8eb6adc443fe    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    9a92223c-b130-450c-be27-175b5cd20691    Price changed to 225 for item ClinicMAT -Amikacin 500mg/2ml (5pce/box)  2026-05-30 04:15:18.892158
75d47fb1-aaed-4b22-9150-e3988015ca61    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 3ae615b7-131c-4905-94c6-1a318f4e3502    \N      2026-05-30 04:16:52.285298
be2f2e73-473c-424b-9cc6-5d864405a3ef    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element e31f36a8-7939-4fd5-b214-ae9c4d24d722    \N      2026-05-30 04:16:52.872243
3ed54602-f530-4bac-addb-255e4d25e0a6    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 101c35b6-c945-4ad0-8f3a-b28bf94e3119    \N      2026-05-30 04:16:53.478868
f87ef26c-a716-4031-86d3-ef8ba07970ec    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 569f116b-b169-4716-95ee-4337123da4c4    \N      2026-05-30 04:16:53.974582
d8b15f1c-e345-4b72-a4cb-0a2e6046beda    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 054828e0-2acb-4564-bb3a-bd44f5ff6648    \N      2026-05-30 04:16:54.479255
c9a12707-20b6-49ae-a028-e3b93f2388d1    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 5c1dbf7a-7bf7-4fc7-b52f-15573bf7ede7    \N      2026-05-30 04:16:55.086964
0dbf4334-eab3-49fe-b2e6-3eca84c2fc50    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 904fa642-c438-401c-88e9-040d756f6672    \N      2026-05-30 04:16:55.589594
6f5a14e5-1929-4d6e-be01-1b71d4063ecf    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 3ec8583e-44da-4f96-a4be-9ef0f2a5557f    \N      2026-05-30 04:17:18.64444
87446989-e305-40a1-aee1-2270cc06015e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 90674441-d296-46ac-a304-5f30bfb6ecb8    \N      2026-05-30 04:17:32.738841
cac49f66-e48c-4723-a533-7249597322f5    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    delete_billing_element  billing_element 90674441-d296-46ac-a304-5f30bfb6ecb8    \N      2026-05-30 04:18:19.71117
2331df2f-db1f-45c0-a1c3-a279ac9169a2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element ad764ea4-0668-47fe-a715-ca7c79738a03    \N      2026-05-30 04:18:51.389117
8fc0be15-f3d9-40cb-b2b4-876eb8560b10    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b55e22f9-8f5d-4778-8909-07eaa4e2e34d    \N      2026-05-30 04:19:06.013699
081c4dd4-27ac-450d-a24f-70539dfd2e2c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element acf8126b-97f4-4be5-bf44-b9caf6c15760    \N      2026-05-30 04:19:26.381381
2905d16d-bea4-4dd4-8f1a-bdeb1bacf2df    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    58ac3468-68be-4292-a89c-e54113afe127    Price changed to 180 for item ClinicSRV -Apply/Change Bandage   2026-05-30 04:21:56.378864
bc5d80a7-3faa-42de-bc38-18b49f7f67ad    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    09e5ea1e-bdbd-40c5-bf88-144ac5736c32    Price changed to 354 for item ClinicMAT -Soffban (12pce/pack)   2026-05-30 04:23:21.474511
53725fb1-8ec1-4c1b-80b6-f83fe9143fcd    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element b59894a3-246b-4a16-bf26-042401d7aa76    \N      2026-05-30 04:24:22.063738
94f63958-8732-489f-834c-c5740272ea84    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element dca77099-6d48-4736-9f52-5b1d99a954b1    \N      2026-05-30 04:24:22.601544
231e735e-bf91-4a73-b3eb-f0a71b463ad3    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 824fca5a-addb-4b35-90bf-fe744ccf16d4    \N      2026-05-30 04:24:23.091373
189362ea-8ce5-4022-9379-99c1d8efc009    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element d71c0ceb-b50d-4fdf-b493-138fd680f2e1    \N      2026-05-30 04:24:23.595533
1672b6b8-c4f7-4e3b-83c1-7fb65a7d955c    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 22340fc4-a127-4533-854c-f8e6a79f1f36    \N      2026-05-30 04:24:24.111867
791b8019-94d0-44d8-8f46-d30bb12985fe    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    71503f5b-25c9-418a-bf39-2c8df2215d2f    Price changed to 69.30 for item ClinicMAT -Tensoplast Bandage 10cm Roll 2026-05-30 04:25:31.359853
7c190066-5d25-4577-a871-2f782c10c5f3    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 2866cda8-3f07-4cac-8fa1-aee788105cf6    \N      2026-05-30 04:25:47.977044
e288572a-bb14-4e59-ba9c-3e844e541efa    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    sync_netsuite_customers customers       bulk    created=0 unchanged=2 total=2 skipped=0 2026-05-30 04:36:30.782483
2cc29354-ed18-4913-8d11-21f667dbe41a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 7eb0b1fb-5424-416c-8986-f55ab8e0f032    \N      2026-05-30 04:49:40.681929
778b2760-c5fc-4a82-ba56-50e921a75881    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 6bba616c-f50a-423d-9c48-17aec5099d28    \N      2026-05-30 04:51:21.8978
195e44ea-5d45-4e26-b22c-15176b4a3f34    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    change_item_price       item    10cb955d-f9ca-4602-a517-9109f89b2dfa    Price changed to 250 for item ClinicSRV -Ultrasound Re-Check    2026-05-30 04:53:29.26986
68354fe6-a920-477b-9b89-3b301faed295    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element eb41381c-93bd-4396-aaff-3a083eb185b1    \N      2026-05-30 04:53:48.710525
ef1f4b68-ebaa-4ce8-bd97-53be39af7468    853acd7c-4759-4213-ace1-b7da16385a52    admin   sync_netsuite_customers customers       bulk    created=1 unchanged=2 total=3 skipped=0 2026-06-01 05:24:52.392337
cd8c84ba-2e45-4b02-97f2-a0f39bcad93e    51e90911-2110-4d9b-8278-f7a1b0dd366c    Zeid    sso_login       user    51e90911-2110-4d9b-8278-f7a1b0dd366c    SSO login via Unified Portal    2026-06-01 05:47:17.23941
497ee53a-5ab3-4065-ab85-9f33d7134a7c    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_agreement        agreement       19397653-4da2-40f5-a33d-1fb6350c2cb5    Created agreement: LA-2026-8260 2026-06-01 06:23:58.944301
a04d90b2-75ff-4e0d-aec8-34fc87b667fe    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_agreement        agreement       d0cdf354-5cf5-4ab4-bb91-f678eb63637c    Created agreement: LA-2026-6487 2026-06-01 06:25:07.440381
dcc5650c-e88d-4f36-bf0d-7fdb3788f133    51e90911-2110-4d9b-8278-f7a1b0dd366c    Zeid    sso_login       user    51e90911-2110-4d9b-8278-f7a1b0dd366c    SSO login via Unified Portal    2026-06-01 06:26:35.200116
2dd9ef4f-9177-430f-9636-503ee0f354f3    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_agreement        agreement       8e4e40ab-9a5a-47eb-b8a7-601eed34fe70    Created agreement: LA-2026-6360 2026-06-01 06:29:17.275306
fe534bd8-6310-4152-b4d9-9d710dbf75e3    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 0b6a455d-2692-463e-ab6a-b873f8840b3a    \N      2026-06-01 06:35:45.375368
276fe0c2-b0f2-4fbc-b1e4-6736059ed157    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_agreement        agreement       0e5b97e5-d40c-4441-af32-7e0c0b4ebeb2    Created agreement: LA-2026-2146 2026-06-01 06:46:32.850061
c26a3ad6-1577-4127-99bd-a68e7e76d900    fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae create_billing_element  billing_element 3af881e2-532b-4b67-b396-30015247d2dd    \N      2026-06-01 06:50:28.676292
11b72a86-3b6a-48d3-9190-c9cc1d305fd7    853acd7c-4759-4213-ace1-b7da16385a52    admin   sync_netsuite_items     items   bulk    created=5 updated=251 unchanged=1908 total=2164 2026-06-01 06:50:59.656181
f9b1ab16-86d4-467d-83cc-6517e3d2e6a1    853acd7c-4759-4213-ace1-b7da16385a52    admin   sync_netsuite_items     items   bulk    created=0 updated=0 unchanged=2164 total=2164   2026-06-01 08:12:19.319303
7aff2926-59f3-4a5c-9296-5d66683b0140    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 46954efe-a8ae-4215-a9e8-cf08f04b3c8c    \N      2026-06-01 08:28:40.457882
a5e7ce93-c044-4fa8-9108-ec57a9b3a207    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element d8919882-8bd0-4c7c-8207-18a3ecbe7107    \N      2026-06-01 08:28:40.907888
bc7b4f55-6d77-4ae6-aab1-68a7a314b1b8    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 64d6ccca-940f-4b1e-ac1c-74b437548c54    \N      2026-06-01 08:28:41.444415
34be632c-3981-41d9-b021-a5ded7f0bd78    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 4ff9c3ca-6657-45ff-9e8f-4ea3c8c26f0f    \N      2026-06-01 08:29:34.523354
6b7e0f6f-9b82-44a7-9df8-72ae02f5adb3    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 980bcaca-f9e2-494e-ae1c-50a584b6ec25    \N      2026-06-01 08:30:41.16346
a00bf55e-c9ef-4360-b910-434f8021883b    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element bed53cbd-bc05-42e7-85a5-3e0b88530c98    \N      2026-06-01 08:30:41.69221
7c2f2e1a-96aa-4c34-a1c5-d5b0c0d25c20    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   update_billing_element  billing_element 46954efe-a8ae-4215-a9e8-cf08f04b3c8c    \N      2026-06-01 08:32:27.358338
01925247-09d0-4a83-a98f-08b6fd054d53    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   update_billing_element  billing_element d8919882-8bd0-4c7c-8207-18a3ecbe7107    \N      2026-06-01 08:32:37.12872
76e31121-dcda-493a-9f82-824f35ac1285    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   update_billing_element  billing_element 4ff9c3ca-6657-45ff-9e8f-4ea3c8c26f0f    \N      2026-06-01 08:32:50.934337
7e5f4c1b-924c-45fd-a4b4-e9e7614ace2f    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element f4d0ed96-7319-4c55-abde-37d33dc9d219    \N      2026-06-01 08:34:31.23761
6810d6d6-cefd-4328-bca5-34fb22ca1901    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element a22c56f3-6f6b-421e-baf5-37f890695ae5    \N      2026-06-01 08:39:15.008089
5aec1280-9011-49a9-b58b-8312732c16d3    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 3fd7748f-063d-4e8e-b198-5bde474e857a    \N      2026-06-01 08:39:46.213679
8e6794a0-48cd-4018-b077-a35804279f74    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 63b8ee6e-2480-441b-b0e3-967cfb1f5fe1    \N      2026-06-01 08:41:30.869043
f3f19b01-bb4f-4e05-9486-75aaefaf4631    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element ee4804b4-43f5-4571-b21c-380bd697d2eb    \N      2026-06-01 08:41:31.37212
9d26de68-f742-4c8b-ac24-bda396fcb499    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 84241a1d-3a57-44b5-a884-e21e05343848    \N      2026-06-01 08:41:31.881853
e287926c-043c-4af5-aed1-e3d4f1f1a061    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element d0222ac5-d6bc-4f81-8b7f-22d3eb312ede    \N      2026-06-01 08:43:11.766758
f956d6cd-6e67-4e55-a699-775906c5bec9    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 2fdb91bb-2897-4c6a-a245-b8885652cb61    \N      2026-06-01 08:43:40.697211
844d419a-84c2-4a00-b556-5cee9aeb8d78    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 629abb6d-cf90-4b31-8a98-f13731d721f3    \N      2026-06-01 08:46:17.212163
204ac07c-e1d5-44d0-9c1e-d7f5043c6964    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 6235df33-3ca1-4f5c-92ab-da22d01d7288    \N      2026-06-01 08:46:17.702908
f4beb931-d946-4dca-aafa-dd859328a4f5    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 6f8a27d1-34bc-4b29-a611-56d4edb40fa8    \N      2026-06-01 08:47:35.061991
ee8f71ed-02fd-481b-8e1e-72ee385c2fb9    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 617ab804-9668-4f9b-8183-3ac501185ed2    \N      2026-06-01 08:47:35.601376
35c9cd09-609e-45d5-a0e0-09507fc64d93    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element ab6cffa7-8f8d-4717-ad3a-c7a4528e333d    \N      2026-06-01 08:48:10.9325
ee8e3905-2e27-4813-b0d7-dc764687421d    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 53626801-14ca-4339-a385-64e553d9ab2c    \N      2026-06-01 08:48:44.453024
72359b86-631b-41a1-8e87-f0a427c1ed68    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   update_billing_element  billing_element 53626801-14ca-4339-a385-64e553d9ab2c    \N      2026-06-01 08:49:04.010484
43e5aefd-6dfc-4f41-b230-dfa4a0e04832    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element d2f3f863-8322-4065-a083-c93ed5b53546    \N      2026-06-01 08:51:15.149036
d9e0ce69-f2a6-4496-b4a1-a1535d180ae1    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element f6648681-1ae2-447f-b027-93d8106b0cd9    \N      2026-06-01 08:52:01.438464
e8342733-2c82-47c4-b7b7-7981a7964618    50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   create_billing_element  billing_element 7908028a-6e31-41da-b56b-40a7578887a6    \N      2026-06-01 08:52:29.115119
783bd03b-45da-4fdf-b368-0380d26e2a5a    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    sync_netsuite_customers customers       bulk    created=1 unchanged=3 total=4 skipped=0 2026-06-01 09:21:52.711261
40bd2215-3364-4f0b-987e-2d04f1f87e09    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 271e8753-7df8-4314-b4d9-d69d387c7f44    \N      2026-06-01 09:32:27.850548
023f407a-bb35-4e44-8e7e-3d0f981d629e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element c00a19a5-e5bc-4a21-819c-958174504fe6    \N      2026-06-01 09:32:28.452386
7f0fb3c4-b9d3-41af-92fe-58310c2283b4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element c1d05498-a953-4178-ba0f-b9316a4c64d3    \N      2026-06-01 09:33:35.545592
3e082c0f-d4a2-45d9-b606-7bab7b931522    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    create_billing_element  billing_element 1b972918-d32d-4149-a8dd-d5dc0e4450ef    \N      2026-06-01 09:33:36.019062
16bdf3da-7707-487e-98e2-c9cf308d2c3d    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    sync_netsuite_customers customers       bulk    created=0 unchanged=4 total=4 skipped=0 2026-06-01 09:36:20.550629
d54b684f-e505-42d2-9d7b-4e90e4f3141b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        04794f68-cd75-4a07-b2e1-5bd03908d34d    VET approved for 2026-05        2026-06-01 09:39:29.552118
5297fc8d-fc9d-4ba5-a76f-1de87dcbd38b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        85e59f96-7082-4d49-aed6-7eee38367d8f    VET approved for 2026-05        2026-06-01 09:39:55.60898
7a60d975-ca26-4e5d-9d42-2abd86713faf    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        b62a5a68-335e-4945-83bf-9b6544ca8a5e    VET approved for 2026-05        2026-06-01 09:40:00.402706
e996467e-2f79-408c-b5b2-a4cc2fc753e0    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        57c3243c-a8c6-4d9a-8786-310247633fb9    VET approved for 2026-05        2026-06-01 09:40:28.454175
9c496b68-77d1-4f55-b168-a65fc34a1947    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        c8bd65e9-3c3f-4d36-8384-190495504784    VET approved for 2026-05        2026-06-01 09:40:34.193889
cee33e45-6ad5-483d-8044-769eb82c2a34    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        82989572-76ea-4d8d-84e8-2bd26e4e4b5d    VET approved for 2026-05        2026-06-01 09:42:22.369318
f82150c3-77a6-47e6-9844-7e30b18e7eee    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        532a7e35-e434-4e14-b3be-44856ef22046    VET approved for 2026-05        2026-06-01 09:42:27.152788
5a6897b6-d66d-4c77-a35a-1f582d2c636b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        11f0fb00-f423-4b9c-8740-1dcb79238e0a    VET approved for 2026-05        2026-06-01 09:42:38.272096
ac968e90-b894-4b5d-b0e5-05ef25f15ba4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        aec20ede-5648-4870-b467-0242a87cf1c0    VET approved for 2026-05        2026-06-01 09:42:40.249051
d09d7284-7370-4c77-b2e4-7e8a3f234ab8    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        3766a433-12c3-40aa-88b8-387c9d86250f    VET approved for 2026-05        2026-06-01 09:46:26.430766
39fe4f86-3879-4b4c-b19c-1f1738930d59    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        19ef25e2-409e-4829-a2fc-91284433f060    VET approved for 2026-05        2026-06-01 09:46:31.184913
84efbf9f-5baa-4216-95cb-4c1c292359e0    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        b981e7f2-b006-4156-b8f5-8850002e60c9    VET approved for 2026-05        2026-06-01 09:46:37.262906
95c780fd-de41-4ca5-89ca-baf6180e77c4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        1ff6542c-5bcc-4513-9db8-35ba7e047720    VET approved for 2026-05        2026-06-01 09:46:40.01395
d36b5684-7156-4705-8212-6603f6a5d062    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        47e4d7f1-397a-4f01-8a8c-68a050b0c62b    VET approved for 2026-05        2026-06-01 09:46:43.09938
95180caf-050a-4afc-adc9-2e1e46e02ff5    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        055ea367-2221-4cf3-991c-3ce1bb7572d0    VET approved for 2026-05        2026-06-01 09:46:48.69896
e4955369-27ed-4678-8037-f93589d25033    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        e58df31a-ba23-4ac9-911d-4a6febbae5b2    VET approved for 2026-05        2026-06-01 09:46:51.440943
84e510e8-2589-4e6a-8297-1c580ae40b6e    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        6968a32a-8f0f-4ab7-a786-8b5bd71faad0    VET approved for 2026-05        2026-06-01 09:46:53.33638
77dde403-cca2-499d-96c6-1342d0a97108    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        5862869d-9142-4342-874a-468b28adde30    VET approved for 2026-05        2026-06-01 09:46:57.072884
321c33ad-3398-47b2-b9e9-ff1663c83558    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        3e292297-8dc0-4d06-9cd4-2fdd1489a6f9    VET approved for 2026-05        2026-06-01 09:47:14.137741
07f9f59e-2284-497b-ab9f-a784a338c687    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        663a1967-6be7-4fe7-852f-72b4143af51d    VET approved for 2026-05        2026-06-01 09:48:38.42091
30635888-3b4a-4ffd-9780-13065c6006a6    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        1b728e75-3bc6-4521-b0c9-d636df391bbd    VET approved for 2026-05        2026-06-01 09:48:40.355248
74ade9d3-994c-4d5a-a294-823ab463505f    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        b8dbc24a-993c-4c94-943b-e3226b175cef    VET approved for 2026-05        2026-06-01 09:48:42.589193
b482a59b-4d86-40e8-8d28-ec9cecf1c246    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        63d75419-67d6-4ae9-a6ea-adeaa7e6ffa0    VET approved for 2026-05        2026-06-01 09:48:44.720609
67a9ec87-adf9-480a-a428-387f8ca6ab71    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        69328bf1-6b23-4e80-9d4f-c5d7abde9a33    VET approved for 2026-05        2026-06-01 09:48:47.318473
78e9824b-9226-43d6-87c1-ce641b71bcbe    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        b322a8d0-f3cf-4768-885f-7cca59a87d50    VET approved for 2026-05        2026-06-01 09:48:54.499952
8ee5dd04-51ac-4029-9481-a4ddeb14cfe2    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        e9bab2b7-8705-4f45-875d-b7f8950d6c74    VET approved for 2026-05        2026-06-01 09:49:01.14249
6cc63d44-f2ac-44c6-9f82-41c6b0f4f0dd    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        5ecfaf9b-be1d-4b3b-bf9f-ad0391c5b2dd    VET approved for 2026-05        2026-06-01 09:49:04.650531
7b478df9-5bb7-4009-b860-445dc18000e4    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        b37a76bf-0bab-407f-bfdb-46291573330f    VET approved for 2026-05        2026-06-01 09:49:25.203789
2356f011-fc47-4937-891c-1066dd49f021    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        4823606e-783f-4b8a-b46a-96c5d24c1564    VET approved for 2026-05        2026-06-01 09:49:38.378803
d6dda485-3373-45e6-b2bd-642234b64bb0    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        0fe9eb77-153a-4fc8-ac89-dbb45f9cc2e8    VET approved for 2026-05        2026-06-01 09:49:46.80471
6ad918a6-f12b-45b0-b040-e9f678211124    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        545023ec-1792-4330-b817-70ece6da0a29    VET approved for 2026-05        2026-06-01 09:49:49.945903
da407fef-c85f-4f58-a66e-45917805be50    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        cdedd04b-59d7-4efa-8eba-61dd8ab79e71    VET approved for 2026-05        2026-06-01 09:49:52.33438
ecc7036d-f64c-428a-8fed-e6a70a534365    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        856d3e6f-e5b0-423d-9c75-84134dc1f28a    VET approved for 2026-05        2026-06-01 09:49:56.889227
6dc05f82-50c6-4bb6-a1b1-566b55354d3b    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        e0579cd0-0238-4362-ab22-62a18e56d85b    VET approved for 2026-05        2026-06-01 09:50:01.455408
4f2061df-39e9-4a84-b314-0772010be671    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        dbbac283-cb42-48b9-8b03-0e3f690dd920    VET approved for 2026-05        2026-06-01 09:53:56.873277
cfd4b66e-1252-411d-b7da-f35328fc3734    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        b137e999-ed33-47bb-a774-8b18b34ad489    VET approved for 2026-05        2026-06-01 09:54:45.950921
6a6b2256-1327-47c7-b742-941fba751eae    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        19b13a42-3a19-4d08-9377-8c5446814884    VET approved for 2026-05        2026-06-01 09:54:50.14831
04806d28-c659-4f89-859d-24b597b61d03    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        7b80a918-e230-4bb7-9cd8-8b5f98fe44c1    VET approved for 2026-05        2026-06-01 09:54:58.218274
8e78588b-00a7-4cec-83f7-9a6ab60ba8b8    3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    approve_billing_month   monthly_billing_approval        fff561ed-f5b7-4f29-81b6-2340c1f1721b    VET approved for 2026-05        2026-06-01 09:55:09.434594
\.


--
-- Data for Name: billing_elements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.billing_elements (id, horse_id, customer_id, box_id, item_id, quantity, base, price, transaction_date, billed, invoice_id, created_at, agreement_id, billing_month, user_id) FROM stdin;
d0253f62-770b-44ad-bd67-56f6819410a0    217838db-92a3-4f51-b25a-ee20901329ec    96372285-ae9a-45bb-acbf-95d3447b87bb    2d9bf537-4771-4e91-ad5f-c67e9178d69c    f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-01      f       \N      2026-05-01 13:45:33.350805      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
7071e147-3eb6-416d-bfea-22bb9c461fd8    1c9d36f7-0f9e-48ad-b6ad-471002e4f78d    96372285-ae9a-45bb-acbf-95d3447b87bb    728c2e50-8cfb-4748-bc40-b5e9964c4d1e    f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-01      f       \N      2026-05-01 13:45:57.70208       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
0e0390ae-c5a4-4491-bc96-200ea04606fc    d3ccaeaa-0818-4e87-86b3-3f4602fc27cc    96372285-ae9a-45bb-acbf-95d3447b87bb    f231df6c-a72f-433a-b5ca-a88981152eee    f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-01      f       \N      2026-05-01 13:46:23.172521      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
05008140-f79c-46a2-8288-d87b3ccea64a    169eafb1-86f1-40d5-8fae-095a64208fed    96372285-ae9a-45bb-acbf-95d3447b87bb    06405660-ee33-4a64-a126-b6e072ee6e7c    f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-01      f       \N      2026-05-01 13:46:30.575089      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
ad746c14-78c3-4dc0-aeea-6919e76fd5e6    699ff103-7bd0-4866-a818-2a0b3d3ed141    96372285-ae9a-45bb-acbf-95d3447b87bb    1a74eb4c-4815-4721-824d-4d0443fe307e    f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-01      f       \N      2026-05-01 13:46:48.725105      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
9ceb02e4-b10e-4b56-9674-c6d661100dd8    2328687c-cb15-44cd-adde-141b6d283ccb    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    214bd414-650f-480a-86a5-622c698b63d6    4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1       \N      240.00  2026-05-01      f       \N      2026-05-01 13:59:19.320359      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2fc04f0e-8409-431d-a25e-d45e3e7e3786    3193395a-d8a5-453c-ab8f-3674d4c5b4b8    1c291ce0-4b3a-4765-a88a-6eddae18455d    596ce3b8-9c3b-410c-9385-87d1388e78dc    6069d3b6-f009-4c64-9f6b-2b465729df72    1       \N      340.00  2026-05-01      f       \N      2026-05-02 13:28:33.50024       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
4d5f69db-5f60-496b-b7b7-a61084079987    3388f460-d815-48fc-a427-1289adc0ea2f    1c291ce0-4b3a-4765-a88a-6eddae18455d    c6e77b87-6119-4743-81a3-c10f648599dc    6069d3b6-f009-4c64-9f6b-2b465729df72    1       \N      340.00  2026-05-02      f       \N      2026-05-02 13:29:04.8217        \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
92fed059-51cb-4598-a852-635cdbbcc192    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    96f4a9ae-e972-4dee-bd40-8e8223f2d4c6    1       \N      240.00  2026-05-01      f       \N      2026-05-02 13:29:55.347236      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
3aa2d2da-7b58-42cb-9b08-8b3365e36289    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1       \N      240.00  2026-05-01      f       \N      2026-05-02 13:48:09.503327      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
d041c226-2df8-4810-af1e-720a5bf2c923    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    f3428cfb-d0ff-4a6f-b13c-9e42b4cf1e84    1       \N      400.00  2026-05-01      f       \N      2026-05-02 13:48:10.011404      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
db274b78-fbc2-467d-b61e-e561671c1636    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    cde77c22-7efb-47f5-a23f-62c5e1e32016    1       \N      175.00  2026-05-01      f       \N      2026-05-02 13:48:10.479428      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b424d2e9-7571-42b5-b84c-97f47eb2bcf9    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    1edb2d92-f0d7-428e-8866-951b4dce645f    1       \N      2200.00 2026-05-01      f       \N      2026-05-02 13:48:10.930309      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
57e02fa3-5e4b-4ba9-b27d-43312ca607db    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    16b787e1-e9eb-4253-b02b-f75a0747e4a4    2       \N      600.00  2026-05-01      f       \N      2026-05-02 13:48:11.387376      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b5139dc6-831e-4e75-bd9c-6a83a314ebaf    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    9e2ec26d-2c40-42ca-b10a-aa241f21c6bf    1       \N      300.00  2026-05-01      f       \N      2026-05-02 13:48:11.889372      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
6dafe710-5b03-42da-83a7-7321537aca5b    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    9be7dd7a-0d14-459b-8f1d-11caceabfc6d    2       \N      600.00  2026-05-01      f       \N      2026-05-02 13:48:12.400799      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
4d00aa9b-1b19-46c2-8ec5-4240dc881668    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    4dda5637-1500-46fd-83e0-59f79a3caf95    2       \N      700.00  2026-05-01      f       \N      2026-05-02 13:48:12.821754      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2b5011c0-786a-40c0-890a-477fb89192fc    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1       \N      70.00   2026-05-01      f       \N      2026-05-02 13:48:13.252164      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
21e8ecab-b077-4f66-a2e8-a32ef190a16a    2328687c-cb15-44cd-adde-141b6d283ccb    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    214bd414-650f-480a-86a5-622c698b63d6    c75a5eab-2131-4e8c-a5c7-5c1ce69c3eec    1       \N      120.00  2026-05-01      f       \N      2026-05-02 13:51:39.381882      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
91d3270b-9d11-47a8-ba85-0f201cc333ed    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    cde77c22-7efb-47f5-a23f-62c5e1e32016    1       \N      175.00  2026-05-01      f       \N      2026-05-02 13:54:59.209002      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
95561cd4-b096-411e-bac4-e93ca01c4a2f    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    1edb2d92-f0d7-428e-8866-951b4dce645f    1       \N      2200.00 2026-05-01      f       \N      2026-05-02 13:54:59.754637      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
9e85fdcd-73fa-4ca7-bfb4-1c15be61b86c    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    16b787e1-e9eb-4253-b02b-f75a0747e4a4    2       \N      600.00  2026-05-01      f       \N      2026-05-02 13:55:00.178991      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c342278f-dd8b-4b19-8cc3-678f86ecd54f    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    9be7dd7a-0d14-459b-8f1d-11caceabfc6d    2       \N      600.00  2026-05-01      f       \N      2026-05-02 13:55:00.675612      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
082cd654-3cf2-4114-b1ed-89f5951ba9fe    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    28ce5e3e-5d76-48c7-ab47-23b36a469f86    2       \N      600.00  2026-05-01      f       \N      2026-05-02 13:55:01.111727      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
a23dfa9e-a63f-409c-a02c-f61eb9903d30    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1       \N      70.00   2026-05-01      f       \N      2026-05-02 13:55:01.699798      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
18f02310-ff40-4cc6-9e0c-45cf4c1c2ce8    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    3bba8890-8f31-4721-a1eb-23b1bc82b540    2       \N      25.00   2026-05-01      f       \N      2026-05-02 13:55:02.62165       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
20cb0c32-2ad6-4c9b-85db-343a2908b12b    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    952061b6-9688-4585-96a6-e69b69db106d    0.1     \N      50.00   2026-05-01      f       \N      2026-05-02 13:55:02.155185      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
7691298e-650c-4bb2-aee3-7f91d8536804    94f4a18b-0024-488d-9dc6-487620feb8a6    3fe1302f-fad6-42cd-915e-acef194e13c6    \N      c99e1950-0228-4294-aab9-8a8530eb8a50    4       \N      600     2026-05-02      t       3d6f4e07-87d3-46b2-b058-18e5f001fb22    2026-05-01 20:49:55.716216      \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
d56170d7-bf7e-44c8-9c19-ed85138b7b0a    e32704a3-a4a1-4d54-963c-8c777a4ea7cb    3fe1302f-fad6-42cd-915e-acef194e13c6    \N      c99e1950-0228-4294-aab9-8a8530eb8a50    4       \N      600     2026-05-02      t       3d6f4e07-87d3-46b2-b058-18e5f001fb22    2026-05-01 20:50:27.405292      \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
b27451e0-cfd5-493d-95b2-fb24757aacc4    e97f808a-6c4d-4637-92fc-6692db6b8c01    3fe1302f-fad6-42cd-915e-acef194e13c6    \N      c99e1950-0228-4294-aab9-8a8530eb8a50    4       \N      600     2026-05-02      t       3d6f4e07-87d3-46b2-b058-18e5f001fb22    2026-05-01 20:49:37.06573       \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
96c7587a-bc0a-4713-955b-3b5291e6c9e5    932f95d6-5ae2-4b41-a034-3b0e99285a22    3fe1302f-fad6-42cd-915e-acef194e13c6    \N      c99e1950-0228-4294-aab9-8a8530eb8a50    4       \N      600     2026-05-02      t       3d6f4e07-87d3-46b2-b058-18e5f001fb22    2026-05-01 20:50:13.61294       \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
ffe8379d-b62c-4201-9736-397a8ed891fe    2328687c-cb15-44cd-adde-141b6d283ccb    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    214bd414-650f-480a-86a5-622c698b63d6    d9300ff4-7a1b-4d9f-8154-69c28962fe49    0.16667 \N      130.00  2026-05-01      f       \N      2026-05-01 13:59:19.779035      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
7c2345a5-008c-43a9-8d67-a25a5f2a2af6    55add96b-8f46-4cd4-905b-cb3613d4b244    c0471f15-cf19-4ac7-87da-2931db694ddd    \N      c99e1950-0228-4294-aab9-8a8530eb8a50    2       \N      300     2026-05-02      t       7e1ceb04-00bd-4d52-b0f6-668d6eac094f    2026-05-01 20:48:35.845489      \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
62181d25-a893-4990-916c-ac116c446b55    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    c75a5eab-2131-4e8c-a5c7-5c1ce69c3eec    1       \N      120.00  2026-05-04      f       \N      2026-05-04 10:16:50.715271      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
f561357a-0d6d-4bb4-bb5d-276bd0fa7bd9    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    cde77c22-7efb-47f5-a23f-62c5e1e32016    1       \N      175.00  2026-05-04      f       \N      2026-05-04 10:16:51.287367      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2352a6c0-162e-41ac-bb96-d24e87938755    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    4dda5637-1500-46fd-83e0-59f79a3caf95    2       \N      700.00  2026-05-04      f       \N      2026-05-04 10:16:51.68658       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
0527605f-05b5-414b-9279-aa21c89a9269    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    e6594f6e-5c87-4a9a-8178-02ddc964be1c    2       \N      180.00  2026-05-04      f       \N      2026-05-04 10:16:52.078688      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
15e419e9-f323-41e3-95cf-7b691c4a9f35    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    \N      6764c1fb-1c14-41a7-8fb8-bbf4eb50a01c    1       \N      1250    2026-04-09      f       \N      2026-04-20 10:41:45.400576      \N      2026-04 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
16c8b47f-75cf-41db-8383-513ab2b6582c    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    9cdd868c-8a04-4060-8ee6-e1ded030ae52    1       \N      266.64  2026-05-04      f       \N      2026-05-04 10:16:52.48564       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
11dd6a0d-2851-4f3a-ab31-ca55fb2d010b    31cae8e6-e114-4aad-9715-895c850f1ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      513f0706-ea62-482e-acd0-bd43b9887163    1       \N      360.00  2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-14 09:46:48.497786      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
233050e7-8ebd-49e8-a8e9-29f505ebb57f    31cae8e6-e114-4aad-9715-895c850f1ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      f988eb97-f452-4c9a-bc84-bf71cd195ff3    1       \N      1250.00 2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-14 09:44:56.994715      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
288b1f6d-c525-4ba5-8c7b-aa4bc00ce925    c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      f988eb97-f452-4c9a-bc84-bf71cd195ff3    1       \N      1250.00 2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-09 06:55:33.433824      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2a89e918-5a5f-400c-9708-734908c54348    c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      513f0706-ea62-482e-acd0-bd43b9887163    1       \N      360.00  2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-09 06:58:06.580839      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
440b6825-7f0e-4d4f-b8b9-00b28eb9d2e9    579743ae-5195-4dca-9aae-ac0f5e9c999b    05805800-43a9-43e0-837b-16c566ed2767    71c19df3-c323-4213-a8fa-5b5747689085    6e674600-2edd-40b7-a5a5-f0892a73acbf    1       \N      100     2026-04-18      f       \N      2026-04-20 05:04:06.941822      \N      2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
4ad0c3fa-70df-4e4d-92c7-1413f21022c7    172f33d7-8431-40fc-84ee-2e35db6094e0    c516087b-5ad6-4896-a90d-b865713b411d    3a3b776f-c4c9-471b-ba2a-136fdb7fd98d    6e674600-2edd-40b7-a5a5-f0892a73acbf    1       \N      100     2026-04-18      f       \N      2026-04-20 05:05:52.082764      \N      2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
4ea56e7e-f6c8-4b6b-b781-41daca27b4e3    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    \N      740cd527-345f-43a1-a397-dcba51bd0dcf    1       \N      200     2026-04-09      f       \N      2026-04-20 10:36:11.098845      \N      2026-04 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
4f3747e4-6013-4366-be04-e484342ee8f9    bea61a27-3e66-4b09-93a4-c4a9c71ccde3    b98e1c14-1b11-4953-b795-ff41a2042572    \N      740cd527-345f-43a1-a397-dcba51bd0dcf    1       \N      200     2026-04-09      f       \N      2026-04-20 10:42:11.627108      \N      2026-04 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
6e3a0387-6215-4cb6-8433-0abb341dec99    3b76bd0b-a589-48e3-b4f4-d1edc8d470c3    b98e1c14-1b11-4953-b795-ff41a2042572    \N      6764c1fb-1c14-41a7-8fb8-bbf4eb50a01c    1       \N      1250    2026-04-09      f       \N      2026-04-20 10:42:51.163641      \N      2026-04 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
78aeec3b-b137-40c7-896a-c946d31cb139    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    \N      740cd527-345f-43a1-a397-dcba51bd0dcf    1       \N      200     2026-04-09      f       \N      2026-04-20 10:35:26.824605      \N      2026-04 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
7f86c8cb-1e82-47d8-bc8c-ff64e136ce5d    9f2b32d6-ea20-4dcd-be1c-08e33d516b43    7f34854a-d81f-40ff-b4ec-b2671dcf95ff    bfdaa14a-0158-4eae-9acf-7f58d4b99863    6e674600-2edd-40b7-a5a5-f0892a73acbf    1       \N      100     2026-04-18      f       \N      2026-04-20 05:06:19.971458      \N      2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
33f21ba8-b10e-4842-aa3f-c2dd33d771f0    7fbdf19a-ea91-4a99-a23b-03a7727dd6d8    b6d8a1ce-72af-4a68-b544-0cd212191cc2    286ddcad-9db6-4b76-9e14-b96bb403493a    3d1a7667-7ce9-4b29-aff4-bc6b5d2010c1    0.07    \N      56.00   2026-05-01      f       \N      2026-04-27 13:45:19.64448       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
32eeaf8f-7163-4137-b055-f447aefb4dee    7777790e-5fa9-431b-a7db-fab89730eb7f    05805800-43a9-43e0-837b-16c566ed2767    f93cd1d5-a6c5-4e76-8171-a385f3777783    f3428cfb-d0ff-4a6f-b13c-9e42b4cf1e84    1       \N      400.00  2026-05-01      f       \N      2026-05-01 13:23:30.869227      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
877185e5-7048-44fc-98db-3aa0defdbd5e    3ebae8af-8b4c-41f4-8dd7-865708466f62    e6d95ffc-10c1-499e-b300-17235bcb2aee    6a8b068d-9544-4486-b976-3b360a04e42f    cde77c22-7efb-47f5-a23f-62c5e1e32016    1       \N      175.00  2026-05-01      f       \N      2026-05-01 13:44:49.146619      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
72dc7eac-7336-4a35-90ed-4ecaf53ca940    3ebae8af-8b4c-41f4-8dd7-865708466f62    e6d95ffc-10c1-499e-b300-17235bcb2aee    6a8b068d-9544-4486-b976-3b360a04e42f    28ce5e3e-5d76-48c7-ab47-23b36a469f86    0.5     \N      150.00  2026-05-01      f       \N      2026-05-01 13:44:49.619367      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
9f311942-0a2c-4fe1-9d12-f23c7efb6921    3ebae8af-8b4c-41f4-8dd7-865708466f62    e6d95ffc-10c1-499e-b300-17235bcb2aee    6a8b068d-9544-4486-b976-3b360a04e42f    6e674600-2edd-40b7-a5a5-f0892a73acbf    1       \N      100     2026-04-18      f       \N      2026-04-20 05:03:08.895068      \N      2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
9962bc1a-cffc-4729-bd91-f47e1942dde7    3ebae8af-8b4c-41f4-8dd7-865708466f62    e6d95ffc-10c1-499e-b300-17235bcb2aee    6a8b068d-9544-4486-b976-3b360a04e42f    9be7dd7a-0d14-459b-8f1d-11caceabfc6d    2       \N      600.00  2026-05-01      f       \N      2026-05-01 13:44:50.041756      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c9ee8a3c-0692-43af-b3eb-fe9cb12d8d53    c3cf1475-cef0-4166-bf49-601a888453cc    b26abac0-0aa1-438a-9023-fd0e36882de7    7a08de89-a9f5-4dd5-8b1a-6ce585b57e76    6e674600-2edd-40b7-a5a5-f0892a73acbf    1       \N      100     2026-04-18      f       \N      2026-04-20 05:04:46.52322       \N      2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
cb46e295-9f87-4a73-a5aa-ced4d2147ced    9e2813cf-e97b-4a4e-80a9-1352ead28d94    fd7cee81-6479-4a50-89b4-89b4d0354383    eeef71f9-3da4-4028-a349-7688735b2f7e    6e674600-2edd-40b7-a5a5-f0892a73acbf    1       \N      100     2026-04-18      f       \N      2026-04-20 05:05:24.522076      \N      2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
cdea7dad-1f20-42a0-bc23-b09f48f54413    8da786fe-daae-4d48-8e91-8917843fbff0    b98e1c14-1b11-4953-b795-ff41a2042572    \N      740cd527-345f-43a1-a397-dcba51bd0dcf    1       \N      200     2026-04-09      f       \N      2026-04-20 10:38:16.651044      \N      2026-04 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
d3536e9f-4f85-44f2-86ed-43034c34bca2    3b76bd0b-a589-48e3-b4f4-d1edc8d470c3    b98e1c14-1b11-4953-b795-ff41a2042572    \N      740cd527-345f-43a1-a397-dcba51bd0dcf    1       \N      200     2026-04-09      f       \N      2026-04-20 10:42:32.485648      \N      2026-04 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
d5bc7651-78ff-4d1b-a731-1a587dfdfa42    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    740cd527-345f-43a1-a397-dcba51bd0dcf    1       \N      200     2026-04-03      f       \N      2026-04-20 10:47:08.769689      \N      2026-04 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
f1ea31c1-466f-45ed-9d19-4fd5bc2af8fc    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    \N      740cd527-345f-43a1-a397-dcba51bd0dcf    1       \N      200     2026-04-09      f       \N      2026-04-20 10:41:16.0245        \N      2026-04 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
fc2c55a6-df7c-4aac-9990-c6dc83460ca8    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    6764c1fb-1c14-41a7-8fb8-bbf4eb50a01c    1       \N      1250    2026-04-03      f       \N      2026-04-20 10:44:28.421279      \N      2026-04 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
ff0e28f6-a278-4b22-a3e8-1b4c2820e692    b189c9c9-5544-489e-a977-0efb23c28182    3901dd23-92c5-41d6-9b65-b4b356d1d862    2a5d586a-b056-44cf-8cd1-a35b634adcdd    bdb95c17-955e-414a-a4c1-3f0123fecc7b    1       \N      200     2026-04-21      f       \N      2026-04-22 04:47:42.429295      \N      2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
37352592-5c3a-40ff-8282-e38c0fc2bf47    b5b72cf6-6d71-4831-9699-8f71570787cf    1e44b508-ea1a-4085-a7d8-91bf6035bfc8    ea18dd2c-50c7-45b6-b36e-df0f5a847518    460e2781-6b91-44da-92b7-16aaf8708490    1       \N      160     2026-04-19      f       \N      2026-04-22 12:39:44.24122       \N      2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
6988d106-17d7-4504-9845-18b910b11153    3ebae8af-8b4c-41f4-8dd7-865708466f62    e6d95ffc-10c1-499e-b300-17235bcb2aee    6a8b068d-9544-4486-b976-3b360a04e42f    252bd6ae-6987-4108-8414-d014709cc641    1       \N      150.00  2026-05-01      f       \N      2026-05-01 13:44:50.562233      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
a0cd43a1-4495-48eb-806e-b9195d536c5c    3ebae8af-8b4c-41f4-8dd7-865708466f62    e6d95ffc-10c1-499e-b300-17235bcb2aee    6a8b068d-9544-4486-b976-3b360a04e42f    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1       \N      70.00   2026-05-01      f       \N      2026-05-01 13:44:50.94798       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
16ef95cc-6744-4162-8a10-132be7eb52d9    44cd7916-a904-4878-a7ed-204b372246aa    a6aa0f45-4b7a-4657-9a53-e80c16232d05    fe89df4f-307e-4a15-9080-56e50739987d    8bdc7827-15b9-4b15-b341-08598255ab11    1       \N      1051.00 2026-05-01      f       \N      2026-04-27 14:03:33.558931      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
313f689c-5fc7-4cda-8604-cc6cad60eab1    7fbdf19a-ea91-4a99-a23b-03a7727dd6d8    b6d8a1ce-72af-4a68-b544-0cd212191cc2    286ddcad-9db6-4b76-9e14-b96bb403493a    4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1       \N      240.00  2026-05-01      f       \N      2026-04-27 13:44:15.495388      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2d2f2bc9-ed07-444f-92e3-577597ff31c2    7fbdf19a-ea91-4a99-a23b-03a7727dd6d8    b6d8a1ce-72af-4a68-b544-0cd212191cc2    286ddcad-9db6-4b76-9e14-b96bb403493a    f3428cfb-d0ff-4a6f-b13c-9e42b4cf1e84    1       \N      400.00  2026-05-01      f       \N      2026-04-27 13:44:15.975846      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
a75043da-b8a4-4cea-b4c1-b8be48cf7d34    370ada88-9266-4154-ae13-35e8726bc871    53188f5a-025a-4154-b876-5e4ae1f220ed    efd99a5d-7cb1-4fe8-a119-83f8b792cb0f    2c697218-914b-4cf1-b92c-2befd2d39b7c    1       \N      425.00  2026-04-15      t       3c31925a-5ef1-49c9-8aff-e7cf67cb19c0    2026-04-15 07:17:50.544484      \N      2026-04 50714bb1-7f0e-4363-b470-1c7af22870d4
b7520242-0c81-423f-811a-e0a4632f0650    370ada88-9266-4154-ae13-35e8726bc871    53188f5a-025a-4154-b876-5e4ae1f220ed    efd99a5d-7cb1-4fe8-a119-83f8b792cb0f    d2672769-8460-49f3-8295-2c4857cf01c2    2       \N      300.00  2026-04-10      t       3c31925a-5ef1-49c9-8aff-e7cf67cb19c0    2026-04-15 07:19:38.566478      \N      2026-04 50714bb1-7f0e-4363-b470-1c7af22870d4
be933ca6-7492-4615-aee2-eecf2f0c0902    7a443e5b-439e-406d-9071-7cb8bad8f55d    4939968f-1b46-4d2b-83ed-7c1a29806579    07f4f82d-42f5-46b0-b293-ecfc732178c8    bdb95c17-955e-414a-a4c1-3f0123fecc7b    1       \N      200     2026-04-07      t       4e96dcba-e4e8-4ccc-8ae4-b43fa3880b95    2026-04-20 04:20:41.250307      \N      2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
54851555-0713-4431-9200-75244872db85    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    31a91729-398b-4c5c-81b1-89daf72b7fc5    0.035   \N      21.84   2026-04-03      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-14 11:22:51.006426      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
6fa4e7a0-b59c-4fc3-9a02-0a2953c931c0    fa4ba72a-c067-4cbb-b86a-7e4cf8db638f    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    51f2090e-54fe-4c1a-82d2-b81b5b883dbf    31a91729-398b-4c5c-81b1-89daf72b7fc5    0.015   \N      9.36    2026-04-06      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-14 11:31:56.269871      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
729781ab-2ae5-4d5e-a6f4-4af9e4a58ce5    2328687c-cb15-44cd-adde-141b6d283ccb    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    214bd414-650f-480a-86a5-622c698b63d6    31a91729-398b-4c5c-81b1-89daf72b7fc5    0.035   \N      21.84   2026-04-03      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-14 11:26:14.231494      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2ef0ca36-98f0-47ba-b045-1f4ea3efc30c    31cae8e6-e114-4aad-9715-895c850f1ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      6b109571-1a7b-4d1f-a9a5-fb85fb82e39b    1       \N      2500.00 2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-14 09:45:16.752006      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
31d9a755-6110-4331-9b0f-cd973d3f6150    31cae8e6-e114-4aad-9715-895c850f1ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      e6149f99-35ea-483c-a8a0-01dc1128ffc1    1       \N      100.00  2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-14 09:46:34.649346      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
7a5364c5-5a97-4469-8a3d-6d8d6ea75166    c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      e6149f99-35ea-483c-a8a0-01dc1128ffc1    1       \N      100.00  2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-09 06:57:33.527272      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
98d9e869-ed91-4c77-856d-826dfcd963bc    31cae8e6-e114-4aad-9715-895c850f1ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      dfa5f8c4-8323-48c3-8e01-e4b5bb80b24d    1       \N      600.00  2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-14 09:44:30.760527      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
bf67e5d6-5379-4943-a6d1-f018997081ad    31cae8e6-e114-4aad-9715-895c850f1ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      31a91729-398b-4c5c-81b1-89daf72b7fc5    0.04    \N      24.96   2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-14 11:18:22.485987      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c432b946-048a-480c-857e-61d7c524aaf3    31cae8e6-e114-4aad-9715-895c850f1ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      a3a9985b-b8c5-49b0-b0d8-94c09f8aee8f    0.5     \N      175.00  2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-14 11:18:40.066783      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
e9c37ea6-c204-45df-90ce-9ab91d706e99    c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      6b109571-1a7b-4d1f-a9a5-fb85fb82e39b    1       \N      2500.00 2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-09 06:56:15.029712      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
ee8a7c4e-edd5-4377-94ee-9f626ea8559c    c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      a3a9985b-b8c5-49b0-b0d8-94c09f8aee8f    0.5     \N      175.00  2026-04-14      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-14 11:18:56.75958       \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
f5987dba-e80d-4b72-8d3d-14e2371f955a    31cae8e6-e114-4aad-9715-895c850f1ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      cde77c22-7efb-47f5-a23f-62c5e1e32016    1       \N      175     2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-14 09:48:21.663192      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
df3b1cb5-2b97-44aa-97f6-0e2c1693ab52    0762095a-5f68-4b59-86f2-766cf9ef2c69    e2c4ce13-deb5-4561-bdeb-504e3c5f7266    d3e34213-0133-4b50-b5ab-70003980350a    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      4500    2026-04-28      t       bc88bf37-fd3c-43d8-9b39-dee15985a4e4    2026-04-28 06:01:34.038203      56886b4c-61c2-4aa8-9f34-765efa27fcdf    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
53dccf2a-c0b8-432f-932e-43c81709b41b    0762095a-5f68-4b59-86f2-766cf9ef2c69    e2c4ce13-deb5-4561-bdeb-504e3c5f7266    d3e34213-0133-4b50-b5ab-70003980350a    66b9958d-cf0c-43a2-b517-a74aacf76647    2       \N      300.00  2026-04-25      t       bc88bf37-fd3c-43d8-9b39-dee15985a4e4    2026-04-25 10:30:21.929742      \N      2026-04 50714bb1-7f0e-4363-b470-1c7af22870d4
df24afe7-0d85-4ff2-9275-56127485d27d    0762095a-5f68-4b59-86f2-766cf9ef2c69    e2c4ce13-deb5-4561-bdeb-504e3c5f7266    d3e34213-0133-4b50-b5ab-70003980350a    76cd6fba-d519-4df9-9cd3-ce99ed8fd0bb    2       \N      350.00  2026-04-25      t       bc88bf37-fd3c-43d8-9b39-dee15985a4e4    2026-04-25 10:30:22.454756      \N      2026-04 50714bb1-7f0e-4363-b470-1c7af22870d4
56edf555-c2b8-40a2-a37e-eeb42d29a538    265dc87b-8136-4af8-bf84-15cce35a2a08    53188f5a-025a-4154-b876-5e4ae1f220ed    29658560-917c-4df5-8606-bf053689b49a    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      4500    2026-04-28      t       3c31925a-5ef1-49c9-8aff-e7cf67cb19c0    2026-04-28 06:01:54.575105      2c051d7f-c850-4255-9048-f017293c0a97    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
de39faf4-9dfe-42ff-8d3c-f81f6e4574fb    370ada88-9266-4154-ae13-35e8726bc871    53188f5a-025a-4154-b876-5e4ae1f220ed    efd99a5d-7cb1-4fe8-a119-83f8b792cb0f    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      4500    2026-04-28      t       3c31925a-5ef1-49c9-8aff-e7cf67cb19c0    2026-04-28 06:01:54.575105      eab9ed85-8908-44b6-97c4-9c087807aa27    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
66124152-e585-47d1-87bb-83991d60879f    265dc87b-8136-4af8-bf84-15cce35a2a08    53188f5a-025a-4154-b876-5e4ae1f220ed    29658560-917c-4df5-8606-bf053689b49a    17de3b72-bbc3-412e-a6d8-0e9afcc70def    1       \N      300.00  2026-04-05      t       3c31925a-5ef1-49c9-8aff-e7cf67cb19c0    2026-04-25 10:47:01.84274       \N      2026-04 50714bb1-7f0e-4363-b470-1c7af22870d4
2eb2e712-935b-4f54-8a34-007b1ddc5429    7a443e5b-439e-406d-9071-7cb8bad8f55d    4939968f-1b46-4d2b-83ed-7c1a29806579    07f4f82d-42f5-46b0-b293-ecfc732178c8    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      4500    2026-04-28      t       4e96dcba-e4e8-4ccc-8ae4-b43fa3880b95    2026-04-28 06:35:46.757897      4b976b15-0ba5-487b-bbb6-6b83753c2e0a    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
aeb216b3-1b4b-43a1-b557-aec0b5d07c4a    217838db-92a3-4f51-b25a-ee20901329ec    96372285-ae9a-45bb-acbf-95d3447b87bb    2d9bf537-4771-4e91-ad5f-c67e9178d69c    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      2500    2026-04-28      t       a1c6fcc8-f688-4575-b089-780f1e174c58    2026-04-28 06:35:57.270934      976428ba-6eaa-483c-b01d-1d0fb91f0955    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
b71cc5a2-8b96-4f11-8564-2b736afd67c9    d3ccaeaa-0818-4e87-86b3-3f4602fc27cc    96372285-ae9a-45bb-acbf-95d3447b87bb    f231df6c-a72f-433a-b5ca-a88981152eee    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      2500    2026-04-28      t       a1c6fcc8-f688-4575-b089-780f1e174c58    2026-04-28 06:35:57.270934      e8e4adb3-7be3-435d-8d94-15c157586e38    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
0b314cc5-9f21-4ac1-a63d-275db2914fc5    699ff103-7bd0-4866-a818-2a0b3d3ed141    96372285-ae9a-45bb-acbf-95d3447b87bb    1a74eb4c-4815-4721-824d-4d0443fe307e    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      2500    2026-04-28      t       a1c6fcc8-f688-4575-b089-780f1e174c58    2026-04-28 06:35:57.270934      78f872d8-f649-42a0-9bfa-e2170cfeabab    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
40b692b5-8482-4403-9288-72e74131a32f    1c9d36f7-0f9e-48ad-b6ad-471002e4f78d    96372285-ae9a-45bb-acbf-95d3447b87bb    728c2e50-8cfb-4748-bc40-b5e9964c4d1e    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      2500    2026-04-28      t       a1c6fcc8-f688-4575-b089-780f1e174c58    2026-04-28 06:35:57.270934      c697f17b-cdef-47e5-b0cb-9cd9ed1a3ba0    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
8c94d41c-4fe5-4c22-9cf5-bdcccab71d95    cf937986-711a-402c-87e1-66c76e50576d    96372285-ae9a-45bb-acbf-95d3447b87bb    3c790387-76fc-4fd1-893d-884498cbd8da    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      2500    2026-04-28      t       a1c6fcc8-f688-4575-b089-780f1e174c58    2026-04-28 06:35:57.270934      275d4902-18fc-408f-ba3b-1919ee02cb4c    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
fc5c54c8-baa1-4715-812c-682b74def7d3    70520442-1ef3-4156-94c1-aec49d4bdf79    96372285-ae9a-45bb-acbf-95d3447b87bb    201edc18-e979-4795-9396-e11f7a579347    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      2500    2026-04-28      t       a1c6fcc8-f688-4575-b089-780f1e174c58    2026-04-28 06:35:57.270934      4291bb46-d0c8-4e02-b3bf-4e8e8fd688c1    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
107cec78-29db-409c-972c-80e35598da06    68c49dc9-9880-4115-99a6-c8dbd28b760d    96372285-ae9a-45bb-acbf-95d3447b87bb    5fb2de9e-1363-42ac-93e7-8504fb0062fd    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      2500    2026-04-28      t       a1c6fcc8-f688-4575-b089-780f1e174c58    2026-04-28 06:35:57.270934      4f952c41-1621-4e7c-a528-e9ebef8515c4    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
92fe317d-4d65-468e-b0e2-92d630554333    169eafb1-86f1-40d5-8fae-095a64208fed    96372285-ae9a-45bb-acbf-95d3447b87bb    06405660-ee33-4a64-a126-b6e072ee6e7c    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    1       \N      2500    2026-04-28      t       a1c6fcc8-f688-4575-b089-780f1e174c58    2026-04-28 06:35:57.270934      8c90c419-24bd-4104-b2a2-72761f446676    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
03d4ee23-1202-4df8-800c-a24c4586a679    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    48ac9592-3ac7-4b32-a92a-dc80d02c3089    1       \N      5999    2026-04-28      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-28 06:36:04.623566      e39c91ed-d36a-44e7-8c73-dbf93042ed7c    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
3feabc8c-cb19-4142-81e2-beb739c31da9    fa4ba72a-c067-4cbb-b86a-7e4cf8db638f    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    51f2090e-54fe-4c1a-82d2-b81b5b883dbf    48ac9592-3ac7-4b32-a92a-dc80d02c3089    1       \N      5999    2026-04-28      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-28 06:36:04.623566      79da59f7-d58a-4792-8285-f4b2903debb0    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
4c66e6bd-d725-4094-9025-03b5fd5ee037    2328687c-cb15-44cd-adde-141b6d283ccb    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    214bd414-650f-480a-86a5-622c698b63d6    48ac9592-3ac7-4b32-a92a-dc80d02c3089    1       \N      5999    2026-04-28      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-28 06:36:04.623566      963ccac2-3504-4977-8cb9-b8ae24be4ecb    2026-04 975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a
7ff9cadb-d4dd-490b-b570-c6370ae3d6b5    fa4ba72a-c067-4cbb-b86a-7e4cf8db638f    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    51f2090e-54fe-4c1a-82d2-b81b5b883dbf    cde77c22-7efb-47f5-a23f-62c5e1e32016    1       \N      175.00  2026-04-06      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-14 11:26:43.740067      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
8b64c4f3-f0fb-4738-9675-251419520829    fa4ba72a-c067-4cbb-b86a-7e4cf8db638f    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    51f2090e-54fe-4c1a-82d2-b81b5b883dbf    feb9c32d-24b5-47cb-97bc-a7297557695b    1       \N      300.00  2026-04-06      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-14 11:32:15.774287      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
911d512e-266e-4bb6-845e-6b4563250907    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    cde77c22-7efb-47f5-a23f-62c5e1e32016    1       \N      175     2026-04-03      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-14 11:21:18.89889       \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
950166e9-1ae7-4ef2-9413-9429bf76e2bc    2328687c-cb15-44cd-adde-141b6d283ccb    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    214bd414-650f-480a-86a5-622c698b63d6    feb9c32d-24b5-47cb-97bc-a7297557695b    1       \N      300.00  2026-04-03      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-14 11:26:28.608253      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
95cdd077-aa67-4d8e-a51c-41839013c9f2    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    feb9c32d-24b5-47cb-97bc-a7297557695b    1       \N      300.00  2026-04-03      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-14 11:23:29.539137      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
a019f985-2588-4644-8f39-e88e163f13f1    2328687c-cb15-44cd-adde-141b6d283ccb    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    214bd414-650f-480a-86a5-622c698b63d6    cde77c22-7efb-47f5-a23f-62c5e1e32016    1       \N      175.00  2026-04-03      t       c0234e40-99f7-4723-b737-357c08de3025    2026-04-14 11:25:32.622444      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
5d9d0ab2-aac6-4562-84f7-84b7e01bc59c    31cae8e6-e114-4aad-9715-895c850f1ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    \N      edc7d7ae-4e8b-4a37-8aa4-00bee9186849    1       \N      200.00  2026-04-01      t       e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    2026-04-28 10:55:20.955936      \N      2026-04 3823058b-4ef5-4c22-913f-9cd149cbb6e0
9a05cf11-b58d-493e-b4bf-b207f4d65cf8    cf937986-711a-402c-87e1-66c76e50576d    96372285-ae9a-45bb-acbf-95d3447b87bb    3c790387-76fc-4fd1-893d-884498cbd8da    f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-01      f       \N      2026-05-01 13:45:45.945715      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
1d1606fb-47b8-4d13-a8f8-e51fb8ba0741    68c49dc9-9880-4115-99a6-c8dbd28b760d    96372285-ae9a-45bb-acbf-95d3447b87bb    5fb2de9e-1363-42ac-93e7-8504fb0062fd    f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-01      f       \N      2026-05-01 13:46:10.811809      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
4aadbc49-3837-4bca-bb23-bd86371ed9bf    70520442-1ef3-4156-94c1-aec49d4bdf79    96372285-ae9a-45bb-acbf-95d3447b87bb    201edc18-e979-4795-9396-e11f7a579347    f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-01      f       \N      2026-05-01 13:46:40.393304      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
5e4bb2db-f39a-48c0-951f-e8a1e68fb9c3    19055267-8534-43b8-88ee-a303a114c8de    8f423989-21f2-46e2-adf5-6c47f716f5af    3cead808-232f-4d8a-926f-f3c84c731211    6069d3b6-f009-4c64-9f6b-2b465729df72    1       \N      340.00  2026-05-01      f       \N      2026-05-02 13:28:52.542608      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
011f3ce2-ac1b-4ee0-875d-fa5b00fe1c99    77c11e6d-5270-48e0-a0fc-75e34e6a8e95    1c291ce0-4b3a-4765-a88a-6eddae18455d    3bae3844-10d8-4140-b2fb-468b35bd5640    6069d3b6-f009-4c64-9f6b-2b465729df72    1       \N      340.00  2026-05-01      f       \N      2026-05-02 13:29:21.985974      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
e0a2d8c8-2d29-4048-8214-a000ca1b560e    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    66765bc5-f937-4071-b6b0-19f979447d20    1       \N      56.00   2026-05-01      f       \N      2026-05-02 13:36:17.813751      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
4061bcde-deea-4eb5-87c8-32d0aea07b18    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1       \N      70.00   2026-05-01      f       \N      2026-05-02 13:36:18.414699      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
18f3366f-38b8-429d-848c-3fe653a2551c    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    612e5ad2-02ab-4994-9a3d-b056503c561c    1       \N      250.00  2026-05-01      f       \N      2026-05-02 13:36:20.01448       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
eb9ecdfb-c619-4c87-a429-1faf8cc333f1    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1       \N      240.00  2026-05-01      f       \N      2026-05-02 13:54:58.253294      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c423cba8-13d1-4a86-bd4f-93fc9df3823c    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    f3428cfb-d0ff-4a6f-b13c-9e42b4cf1e84    1       \N      400.00  2026-05-01      f       \N      2026-05-02 13:54:58.763487      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2ebdf2f0-4110-4216-b91c-5ae5a8e811e7    55add96b-8f46-4cd4-905b-cb3613d4b244    c0471f15-cf19-4ac7-87da-2931db694ddd    \N      c99e1950-0228-4294-aab9-8a8530eb8a50    1       \N      150     2026-05-03      t       7e1ceb04-00bd-4d52-b0f6-668d6eac094f    2026-05-04 04:44:44.109081      \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
48c95499-834d-4edb-a2ce-9975acd1af3a    0593cfda-a5bd-4fea-a12a-7a0434121eb7    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-07      f       \N      2026-05-07 08:44:53.885263      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
76640e02-6678-4579-9f18-4dd45bac046b    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    f1383820-34d0-46c1-af5d-b0368a043731    0.25    \N      94.50   2026-05-01      f       \N      2026-05-02 13:36:19.497131      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
43388791-9bd4-4dad-a024-49150d452f16    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    dceba4f6-a5bc-4a50-97eb-008121b1489b    0.1     \N      30.00   2026-05-01      f       \N      2026-05-02 13:36:18.874506      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
60e128f7-1f36-40b5-a357-a39c811f665e    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    cb977323-d2c1-4c9c-864c-f589e8196dc6    0.04    \N      20.00   2026-05-01      f       \N      2026-05-02 13:36:20.513366      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
7332e8e1-f3d0-41ef-8c8d-09995bba0e21    3ebae8af-8b4c-41f4-8dd7-865708466f62    e6d95ffc-10c1-499e-b300-17235bcb2aee    6a8b068d-9544-4486-b976-3b360a04e42f    952061b6-9688-4585-96a6-e69b69db106d    0.1     \N      50.00   2026-05-01      f       \N      2026-05-01 13:44:51.358229      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
8a8437f0-68a2-4651-a966-07706100fbb2    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1       \N      70.00   2026-05-04      f       \N      2026-05-04 10:16:52.901284      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c5129a13-ac29-4c4f-89d4-9c7c1bdedd3d    4aa7bb18-d21f-421f-b2c0-8cb7ca16ae90    69f1447c-0580-44d2-a699-f4dc2ce56ee5    b0cf9824-3634-4b33-aba1-0990e8cc240f    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1       \N      70.00   2026-05-01      f       \N      2026-05-04 10:27:12.654004      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b233b7d2-c865-471f-826f-b2ed8f7ef70c    4aa7bb18-d21f-421f-b2c0-8cb7ca16ae90    69f1447c-0580-44d2-a699-f4dc2ce56ee5    b0cf9824-3634-4b33-aba1-0990e8cc240f    7de3ded2-98ca-4e41-afaf-347410e44f18    1       \N      125.00  2026-05-01      f       \N      2026-05-04 10:27:13.078306      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
d2100b0a-a5ee-4f57-8900-66258ac1fd64    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    dc3474e9-1bda-44df-9324-49f155bba5c6    1       \N      30.00   2026-05-05      f       \N      2026-05-05 10:32:17.131877      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
819dd43f-92a0-408b-9b46-9043697e81aa    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1       \N      240.00  2026-05-05      f       \N      2026-05-05 14:00:32.77577       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
ca72a355-73b0-4ca3-bbd5-bba99f217313    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    f1567c9c-be47-4be0-9005-2bbd561bf765    1       \N      180.00  2026-05-05      f       \N      2026-05-05 14:00:33.229066      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
66d43c7f-eb86-43bd-84c8-d6f0cbdef6a2    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    5b2c8e4b-f4b2-4c45-aa3c-4f971a2a7b69    1       \N      180.00  2026-05-05      f       \N      2026-05-05 14:00:33.72499       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
3c5bfd90-e4f3-4309-9897-2d307fd98ca9    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    3bba8890-8f31-4721-a1eb-23b1bc82b540    1       \N      12.50   2026-05-05      f       \N      2026-05-05 14:00:34.657551      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
4269bcbe-d30f-4535-94e5-c63373585e36    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1       \N      240.00  2026-05-07      f       \N      2026-05-07 08:37:57.912558      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
8b6f6a80-f001-42ea-854c-4765212bf693    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    cde77c22-7efb-47f5-a23f-62c5e1e32016    1       \N      175.00  2026-05-07      f       \N      2026-05-07 08:37:58.432094      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
d01758ea-ae5d-4a00-a144-35bff5eb7c53    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    b35649fd-0d77-4ea6-a6e6-3f913448911f    1       \N      300.00  2026-05-07      f       \N      2026-05-07 08:37:58.902935      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
db29253a-6bed-43b4-a2ce-a361dee95083    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    9be7dd7a-0d14-459b-8f1d-11caceabfc6d    2       \N      600.00  2026-05-07      f       \N      2026-05-07 08:37:59.348318      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
05f8b202-941c-460c-b1bc-1e11101055fc    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    4dda5637-1500-46fd-83e0-59f79a3caf95    2       \N      700.00  2026-05-07      f       \N      2026-05-07 08:37:59.857213      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c33ec13e-1b39-4e50-a4aa-00f8bf5774bc    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    252bd6ae-6987-4108-8414-d014709cc641    1       \N      150.00  2026-05-07      f       \N      2026-05-07 08:38:00.316411      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
260a575a-1ea9-44cb-a7df-8be61faa2d47    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    d09293ab-4fb8-470f-9df3-37087aea5212    1       \N      350.00  2026-05-07      f       \N      2026-05-07 08:38:00.799507      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
37516455-76c4-4c84-a548-5c0a05af8092    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    e6594f6e-5c87-4a9a-8178-02ddc964be1c    2       \N      180.00  2026-05-07      f       \N      2026-05-07 08:38:01.429509      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
0fe03167-625d-4838-b7f4-3193307c6822    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1       \N      70.00   2026-05-07      f       \N      2026-05-07 08:38:01.867101      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
8c66e30c-6e39-4788-bcb6-988ca3fafa50    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    3d1a7667-7ce9-4b29-aff4-bc6b5d2010c1    0.04    \N      32.00   2026-05-05      f       \N      2026-05-05 14:00:35.052203      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
0a30b4ea-1350-4ab8-b501-93d367193b30    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    2dbbcf5a-acc0-4e55-9d59-180ec55d3745    0.26    \N      72.28   2026-05-05      f       \N      2026-05-05 14:00:34.255447      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
60cf298a-966a-4036-bbb2-900dc734628e    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    b9bb0433-85e7-4e32-b4fe-bc2fbc546754    0.1     \N      40.00   2026-05-05      f       \N      2026-05-05 14:00:35.502444      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
f226bab3-afea-4c27-888f-913daccbd34e    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    3d1a7667-7ce9-4b29-aff4-bc6b5d2010c1    0.04    \N      32.00   2026-05-04      f       \N      2026-05-04 10:16:53.746276      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
56a074f1-892d-497a-971a-9278ae36f339    3ebae8af-8b4c-41f4-8dd7-865708466f62    e6d95ffc-10c1-499e-b300-17235bcb2aee    6a8b068d-9544-4486-b976-3b360a04e42f    9a92223c-b130-450c-be27-175b5cd20691    0.2     \N      33.82   2026-05-01      f       \N      2026-05-04 10:29:54.359019      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
6de9c2a9-0e2d-4cf1-9a5d-87a690739776    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    952061b6-9688-4585-96a6-e69b69db106d    0.1     \N      50.00   2026-05-04      f       \N      2026-05-04 10:16:53.304861      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
1b98dcee-5b37-4f28-9d59-3a80a93b6a40    cc2fccde-6e0c-4f23-bd3d-b1ec586c4c5c    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-07      f       \N      2026-05-07 08:45:01.721679      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
5f02fd5e-9eed-4a52-bf88-645ab08a50de    c86b80d8-72e0-4795-b9fb-63918cf78ad9    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-07      f       \N      2026-05-07 08:45:07.945499      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
06dcff75-3898-45a0-9972-f2e43eb3b4ef    7a2aaa8b-e1ff-4ba8-b9bf-feda58967f24    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-07      f       \N      2026-05-07 08:45:25.470814      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
8267c1a3-807b-4d0d-a01a-f1efbd0fc03e    f47e1e18-6c49-4a0c-8134-24d99f082763    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-07      f       \N      2026-05-07 08:45:32.225946      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
5ba4cac1-04f3-47bf-9950-f82989443228    aca66b02-174c-4e6a-8b39-9469dd117676    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-07      f       \N      2026-05-07 08:45:46.150164      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b808478e-ab7b-489f-9392-a2f6e66f9b64    90b2f161-1add-4428-a2b8-b1808dddb803    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-07      f       \N      2026-05-07 08:45:52.352392      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c61175f3-afb9-42f1-a66d-e6d0bc28da8d    5579fc44-2611-4b72-9ba7-46b5185f8415    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-07      f       \N      2026-05-07 08:45:59.878282      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
42f4315a-95c5-48cc-88f5-cf5d12df738d    9db24d66-dd17-4bc7-b792-28ce08cd0462    e151d01f-d544-41aa-9ace-ffc81e3ce21c    6b3a2f08-412d-4c8e-8716-214e91fa8dad    57429aed-2879-493d-b541-71347a13266a    1       \N      150.00  2026-05-06      f       \N      2026-05-07 08:49:50.399235      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
8f66102a-2ec0-4f27-bd2d-aeffefae4c4e    b22b322c-6035-4697-9309-c8a279786522    369d0d0f-5c75-422f-b983-695a04a7f883    c38baf65-24a8-48a8-b5d9-0b51962718c5    4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1       \N      240.00  2026-05-06      f       \N      2026-05-07 08:50:08.83961       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
94bc17cc-5877-4035-a107-6fab2cb257e9    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    c75a5eab-2131-4e8c-a5c7-5c1ce69c3eec    1       \N      120.00  2026-05-07      f       \N      2026-05-07 08:50:43.676828      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c02cf429-c65e-4792-8db0-8fcb0c820e71    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    3bba8890-8f31-4721-a1eb-23b1bc82b540    1       \N      12.50   2026-05-07      f       \N      2026-05-07 08:50:44.139428      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
92e3bfc0-2f38-4c9c-8bee-d77a20d3facd    ae00da66-b9fb-4874-93d6-802223ac2c80    8ed90e29-86b0-4cfe-a131-c06cb7413956    383c1069-03c1-4a20-96ce-e89c59cad905    db25e6c6-88ec-4341-91dd-1d61e018244b    1       \N      24.24   2026-05-05      f       \N      2026-05-07 08:53:03.798472      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b8a5ccb6-22c9-4aa6-ae47-9ab476063982    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    db25e6c6-88ec-4341-91dd-1d61e018244b    1       \N      24.24   2026-05-05      f       \N      2026-05-07 08:55:15.665114      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
4b3c2566-e6af-4399-8b4a-33c1c2857db5    7fbdf19a-ea91-4a99-a23b-03a7727dd6d8    b6d8a1ce-72af-4a68-b544-0cd212191cc2    286ddcad-9db6-4b76-9e14-b96bb403493a    cb849f39-2cb0-4c35-a03c-953402a8132d    1       \N      400.00  2026-05-08      f       \N      2026-05-08 10:23:04.309884      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
308402bc-a5c4-43c7-94b8-3fc62f802474    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    cc0a7c79-e7b4-4145-a0de-91f9e9e8deca    1       \N      200.00  2026-05-01      f       \N      2026-05-08 11:42:39.044821      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
bf684968-ba71-4b8d-a819-ac210bd99016    7a2aaa8b-e1ff-4ba8-b9bf-feda58967f24    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      2e06201f-ef06-4cdb-aafe-2a5c8efaa28d    1       \N      340.00  2026-05-08      f       \N      2026-05-08 13:25:19.310866      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
52b2da9b-4213-4f7e-9e3c-35a7dfb42773    b753fb55-74f7-4ec8-b6f8-98c32ef37aa2    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      57429aed-2879-493d-b541-71347a13266a    1       \N      150.00  2026-05-07      f       \N      2026-05-10 13:44:01.626787      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
df0c49a7-81f9-4ee2-9580-160ef19dba2d    3f2b4133-ae62-42e6-91ff-e7d2c4455ef5    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      f9a7f2c2-3216-4732-85ea-f1ef4a6db142    1       \N      150.00  2026-05-07      f       \N      2026-05-10 13:44:18.235834      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b37f73a6-c8a7-4f21-a725-3a137bba783e    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    dae09228-c921-4b5d-9e6c-87e5a2daea20    0.16    \N      72.00   2026-05-07      f       \N      2026-05-10 13:56:55.041329      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
972ffb45-05ff-4642-a5b7-08dce925224c    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    07e360bc-92f2-4eac-beb4-0cac5e8b0101    0.08    \N      8.32    2026-05-07      f       \N      2026-05-10 13:56:55.794947      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
1572b631-38cc-476d-9419-79b75a2b317a    3193395a-d8a5-453c-ab8f-3674d4c5b4b8    1c291ce0-4b3a-4765-a88a-6eddae18455d    596ce3b8-9c3b-410c-9385-87d1388e78dc    75f8670c-007d-414b-b2ba-4b45a416b7c9    1       \N      800     2026-05-06      f       \N      2026-05-12 07:52:39.756727      \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
85453fa9-ec49-4c35-9692-7e1cbb7f7da8    2d645649-3681-4c85-bbd5-09d4689b3c8a    297dd6e6-0736-4735-b670-eb51444f8a21    \N      784401d7-ebaf-4a4e-88f9-582444c512fd    1       \N      315.00  2026-05-12      f       \N      2026-05-12 08:18:05.51951       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
cf42778e-81d1-4ff7-9ce7-6a1ff96d03ad    5358f269-d191-476f-ad0b-0338c795e46a    297dd6e6-0736-4735-b670-eb51444f8a21    \N      784401d7-ebaf-4a4e-88f9-582444c512fd    1       \N      315.00  2026-05-01      f       \N      2026-05-12 08:19:01.807138      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2e0e761f-1797-4996-b738-883445131cbc    2caec785-144d-43cb-aca7-b72361396ef4    297dd6e6-0736-4735-b670-eb51444f8a21    \N      784401d7-ebaf-4a4e-88f9-582444c512fd    1       \N      315.00  2026-05-01      f       \N      2026-05-12 08:20:25.70046       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2590cc1f-3ed0-42cc-8790-db594cc5bcd2    3bd0e33d-dbe0-4c57-b684-bdbe04513d7b    297dd6e6-0736-4735-b670-eb51444f8a21    \N      784401d7-ebaf-4a4e-88f9-582444c512fd    1       \N      315.00  2026-05-01      f       \N      2026-05-12 08:20:50.280187      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
750d6891-4a4b-4740-8673-e6611ba5f38d    750ac464-8c94-42e5-b7ad-d37df32d7f27    53946bbc-2874-45af-ad7e-6d3d52dc0c25    \N      2ff1dc27-1d89-451d-9e33-deda80c3f31c    1       \N      350.00  2026-05-01      f       \N      2026-05-12 08:27:24.380152      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
236b0d8c-9dec-427e-aa0d-45de03306a9a    750ac464-8c94-42e5-b7ad-d37df32d7f27    53946bbc-2874-45af-ad7e-6d3d52dc0c25    \N      4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1       \N      300.00  2026-05-01      f       \N      2026-05-12 08:27:24.858979      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
63970c98-02c4-4d32-8b5e-a960f4e7eea7    750ac464-8c94-42e5-b7ad-d37df32d7f27    53946bbc-2874-45af-ad7e-6d3d52dc0c25    \N      83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1       \N      70.00   2026-05-01      f       \N      2026-05-12 08:27:25.27292       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
910bd7dc-0963-4512-a99c-bb346694acc4    4aa7bb18-d21f-421f-b2c0-8cb7ca16ae90    69f1447c-0580-44d2-a699-f4dc2ce56ee5    b0cf9824-3634-4b33-aba1-0990e8cc240f    07e360bc-92f2-4eac-beb4-0cac5e8b0101    0.24    \N      24.95   2026-05-01      f       \N      2026-05-12 08:53:02.139889      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
ac3921b4-44c5-49ce-b8ec-d29c8ee39a99    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    dae09228-c921-4b5d-9e6c-87e5a2daea20    0.16    \N      72.00   2026-05-01      f       \N      2026-05-12 08:55:48.564123      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b1d33c4a-3d62-4bb7-a3de-63dcc332c1a8    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    252bd6ae-6987-4108-8414-d014709cc641    1       \N      150.00  2026-05-01      f       \N      2026-05-12 08:56:45.722294      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b43e2200-5d1f-46ed-a18c-4d50851d3194    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    c52845a1-6209-4f20-a232-2e83c2c522ac    0.16    \N      96.00   2026-05-01      f       \N      2026-05-12 08:57:20.833883      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
d7ff3fc3-ecef-41eb-93f3-f23ad7b0f04f    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    c52845a1-6209-4f20-a232-2e83c2c522ac    0.16    \N      96.00   2026-05-07      f       \N      2026-05-12 08:58:38.139604      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
09d69775-9783-469e-8e6f-fb5e6d63c738    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    31a91729-398b-4c5c-81b1-89daf72b7fc5    0.025   \N      15.60   2026-05-01      f       \N      2026-05-12 09:15:58.631962      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
78e4c3d1-8bc6-45ca-bcca-c05b9243ed16    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    2ee6785f-197b-4ab2-9583-eb41f8ceb0d8    1       \N      125.00  2026-05-01      f       \N      2026-05-12 09:18:35.818306      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
09581903-9c6f-47c2-811c-f32266a93058    0593cfda-a5bd-4fea-a12a-7a0434121eb7    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      05e28e05-df88-4bd8-b38b-5fcad1a689be    1       \N      200.00  2026-05-08      f       \N      2026-05-12 09:47:33.46474       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
14c0f139-51d0-49f4-aa2e-85aafaa4cb78    0593cfda-a5bd-4fea-a12a-7a0434121eb7    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1       \N      70.00   2026-05-08      f       \N      2026-05-12 09:47:33.935333      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
61d4fb61-3330-47d9-acc4-19fd3b625ba0    0593cfda-a5bd-4fea-a12a-7a0434121eb7    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      07e360bc-92f2-4eac-beb4-0cac5e8b0101    0.1     \N      10.40   2026-05-08      f       \N      2026-05-12 09:47:34.381191      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
259fdc80-cf74-499a-a4a8-9d7f7efb05df    b612fd91-53b2-48ce-bc9b-d3f8203c60e0    b90e3585-1e2c-43a7-8116-3792346ecb73    2732f6f6-5e0b-4231-8a5f-d9baaeb411e3    57429aed-2879-493d-b541-71347a13266a    1       \N      150.00  2026-05-11      f       \N      2026-05-12 09:48:13.795296      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
a691e545-75b4-4a66-969c-c075390e07e1    0a87d9f1-9a42-42e7-8062-52f03d34db3e    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    c0d83349-f24a-4c0e-b08c-b9a8d4eca067    c75a5eab-2131-4e8c-a5c7-5c1ce69c3eec    1       \N      120.00  2026-05-11      f       \N      2026-05-12 09:53:07.690774      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
fe97946d-ae7a-4dba-988e-4371313bd0f9    0a87d9f1-9a42-42e7-8062-52f03d34db3e    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    c0d83349-f24a-4c0e-b08c-b9a8d4eca067    f3428cfb-d0ff-4a6f-b13c-9e42b4cf1e84    1       \N      400.00  2026-05-11      f       \N      2026-05-12 09:53:08.127781      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
fd5f15ca-1b09-4bf8-aa7f-12b7b28b2825    0a87d9f1-9a42-42e7-8062-52f03d34db3e    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    c0d83349-f24a-4c0e-b08c-b9a8d4eca067    17d4e825-c298-441e-a85c-c5ff6cbd15a4    1       \N      140.00  2026-05-11      f       \N      2026-05-12 09:53:08.667648      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
f4f01340-3b91-432e-8d67-b575bce3a2b3    7fbdf19a-ea91-4a99-a23b-03a7727dd6d8    b6d8a1ce-72af-4a68-b544-0cd212191cc2    286ddcad-9db6-4b76-9e14-b96bb403493a    3d1a7667-7ce9-4b29-aff4-bc6b5d2010c1    0.04    \N      32.00   2026-05-08      f       \N      2026-05-08 10:23:04.766368      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
3223080e-1279-4c9f-a8e7-07ce8b9faaec    750ac464-8c94-42e5-b7ad-d37df32d7f27    53946bbc-2874-45af-ad7e-6d3d52dc0c25    \N      952061b6-9688-4585-96a6-e69b69db106d    0.05    \N      25.00   2026-05-01      f       \N      2026-05-12 08:27:25.733716      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
d807249d-b495-4759-aa20-80fde2c178a1    750ac464-8c94-42e5-b7ad-d37df32d7f27    53946bbc-2874-45af-ad7e-6d3d52dc0c25    \N      3d1a7667-7ce9-4b29-aff4-bc6b5d2010c1    0.04    \N      32.00   2026-05-01      f       \N      2026-05-12 08:27:26.165844      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2beff791-4925-4a03-b10e-ec49e76960f1    b189c9c9-5544-489e-a977-0efb23c28182    3901dd23-92c5-41d6-9b65-b4b356d1d862    2a5d586a-b056-44cf-8cd1-a35b634adcdd    cde77c22-7efb-47f5-a23f-62c5e1e32016    1.00000 \N      175.00  2026-05-13      f       \N      2026-05-13 08:55:53.964713      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
de8a6831-eae8-437e-9836-3a28a0b56c4f    b189c9c9-5544-489e-a977-0efb23c28182    3901dd23-92c5-41d6-9b65-b4b356d1d862    2a5d586a-b056-44cf-8cd1-a35b634adcdd    31a91729-398b-4c5c-81b1-89daf72b7fc5    0.04000 \N      24.96   2026-05-12      f       \N      2026-05-13 08:55:54.469479      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
06038efc-2047-4be2-abf6-92cec75047e3    b189c9c9-5544-489e-a977-0efb23c28182    3901dd23-92c5-41d6-9b65-b4b356d1d862    2a5d586a-b056-44cf-8cd1-a35b634adcdd    feb9c32d-24b5-47cb-97bc-a7297557695b    1.00000 \N      300.00  2026-05-12      f       \N      2026-05-13 08:55:55.0346        \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
1397f247-aeed-46ad-84d3-206ddb3e4231    31c8d10a-4c86-4312-b87f-789bb093ae64    3901dd23-92c5-41d6-9b65-b4b356d1d862    a6b06986-d142-4366-90dc-64f5ab23ab78    cde77c22-7efb-47f5-a23f-62c5e1e32016    1.00000 \N      175.00  2026-05-13      f       \N      2026-05-13 08:56:38.362993      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
002adfe9-8ee5-41d0-8822-a8d81271526a    31c8d10a-4c86-4312-b87f-789bb093ae64    3901dd23-92c5-41d6-9b65-b4b356d1d862    a6b06986-d142-4366-90dc-64f5ab23ab78    31a91729-398b-4c5c-81b1-89daf72b7fc5    0.02500 \N      15.60   2026-05-12      f       \N      2026-05-13 08:56:38.850697      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
e37aa1ee-8892-4b5a-acbf-18a1a5c7ba85    31c8d10a-4c86-4312-b87f-789bb093ae64    3901dd23-92c5-41d6-9b65-b4b356d1d862    a6b06986-d142-4366-90dc-64f5ab23ab78    feb9c32d-24b5-47cb-97bc-a7297557695b    1.00000 \N      300.00  2026-05-12      f       \N      2026-05-13 08:56:39.315978      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
fe46cec2-6e85-4361-9550-43386afca6aa    0a59f5bc-3e6b-48d5-96dc-854516f946fd    3901dd23-92c5-41d6-9b65-b4b356d1d862    51f2090e-54fe-4c1a-82d2-b81b5b883dbf    cde77c22-7efb-47f5-a23f-62c5e1e32016    1.00000 \N      175.00  2026-05-13      f       \N      2026-05-13 08:57:30.22952       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
81bcc385-7d73-441b-8686-35209c77e990    0a59f5bc-3e6b-48d5-96dc-854516f946fd    3901dd23-92c5-41d6-9b65-b4b356d1d862    51f2090e-54fe-4c1a-82d2-b81b5b883dbf    31a91729-398b-4c5c-81b1-89daf72b7fc5    0.02000 \N      12.48   2026-05-13      f       \N      2026-05-13 08:57:30.741805      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
a6cdaf0f-222c-4586-aac9-27b6148b8afe    0a59f5bc-3e6b-48d5-96dc-854516f946fd    3901dd23-92c5-41d6-9b65-b4b356d1d862    51f2090e-54fe-4c1a-82d2-b81b5b883dbf    feb9c32d-24b5-47cb-97bc-a7297557695b    1.00000 \N      300.00  2026-05-13      f       \N      2026-05-13 08:57:31.24354       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
15270554-114f-479c-88b6-14d391e65a06    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    96f4a9ae-e972-4dee-bd40-8e8223f2d4c6    1.00000 \N      300.00  2026-05-17      f       \N      2026-05-17 17:39:40.506144      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
346bac65-ee5a-4573-9beb-ae08bec1cf27    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    2ee6785f-197b-4ab2-9583-eb41f8ceb0d8    1.00000 \N      125.00  2026-05-17      f       \N      2026-05-17 17:39:41.072459      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
7e275145-5d63-4177-b113-08329e2da0d4    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    cc0a7c79-e7b4-4145-a0de-91f9e9e8deca    1.00000 \N      200.00  2026-05-17      f       \N      2026-05-17 17:39:41.580109      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
e29073b6-2684-443a-bf4a-e24ab791a907    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1.00000 \N      70.00   2026-05-17      f       \N      2026-05-17 17:39:42.092609      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
172e9f10-32cd-4229-85de-73f3fb93331d    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    f1383820-34d0-46c1-af5d-b0368a043731    0.20000 \N      75.60   2026-05-17      f       \N      2026-05-17 17:39:42.612285      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
ec40dc43-99a0-4afd-8051-79fec939d593    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    dceba4f6-a5bc-4a50-97eb-008121b1489b    0.10000 \N      30.00   2026-05-17      f       \N      2026-05-17 17:39:43.119186      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
726cacda-70a6-440a-883b-6822b8180a97    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    a0eddf2e-eaf7-4f88-9907-86a7f6ba443d    1.00000 \N      190.00  2026-05-17      f       \N      2026-05-17 17:39:43.636152      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
24c29d58-1d55-4e2d-9c7d-3032ec8493f6    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    d57435ee-c85d-4511-a1a2-3214629b1ee2    2.00000 \N      144.52  2026-05-17      f       \N      2026-05-17 17:39:44.11847       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
cf820dd4-11a1-481a-9f3a-5b6520b6817a    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    cb977323-d2c1-4c9c-864c-f589e8196dc6    0.04000 \N      20.00   2026-05-17      f       \N      2026-05-17 17:39:44.654664      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
cff21fa4-d1cb-468c-b095-cec15cb334df    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    31a91729-398b-4c5c-81b1-89daf72b7fc5    0.02000 \N      12.48   2026-05-17      f       \N      2026-05-17 17:39:45.15719       \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
8f8d1200-f8fb-4edb-812c-8493acd3a054    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    2ee6785f-197b-4ab2-9583-eb41f8ceb0d8    1.00000 \N      125.00  2026-05-17      f       \N      2026-05-17 17:39:45.680358      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
ce7d9c80-859f-4da8-8a97-473d381eca1d    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    cc0a7c79-e7b4-4145-a0de-91f9e9e8deca    1.00000 \N      200.00  2026-05-17      f       \N      2026-05-17 17:39:46.177352      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
86024855-58f3-4010-880e-8783d07765dd    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    31a91729-398b-4c5c-81b1-89daf72b7fc5    0.02000 \N      12.48   2026-05-17      f       \N      2026-05-17 17:39:46.669844      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2fb86123-075f-471d-aa90-75efe361a8fa    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    2ee6785f-197b-4ab2-9583-eb41f8ceb0d8    1.00000 \N      125.00  2026-05-17      f       \N      2026-05-17 17:39:47.170255      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
3299a96e-fa4a-4cd5-bcfc-e2b07e5d3d79    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    cc0a7c79-e7b4-4145-a0de-91f9e9e8deca    1.00000 \N      200.00  2026-05-17      f       \N      2026-05-17 17:39:47.648687      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
506fd77e-8fe0-42f0-8ed6-18c1705af2f0    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1.00000 \N      70.00   2026-05-17      f       \N      2026-05-17 17:39:48.139275      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b4122884-0ba8-43c2-bdf9-b8ce655b8499    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    dceba4f6-a5bc-4a50-97eb-008121b1489b    0.10000 \N      30.00   2026-05-17      f       \N      2026-05-17 17:39:48.618199      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
e5578c23-e46c-458d-8491-84f2de9aac14    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    8bdc7827-15b9-4b15-b341-08598255ab11    1.00000 \N      1051.00 2026-05-17      f       \N      2026-05-17 17:42:06.518625      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
a7579019-9e93-431b-8744-33f53c46893a    172f33d7-8431-40fc-84ee-2e35db6094e0    c516087b-5ad6-4896-a90d-b865713b411d    3a3b776f-c4c9-471b-ba2a-136fdb7fd98d    6e674600-2edd-40b7-a5a5-f0892a73acbf    1.00000 \N      100     2026-05-16      f       \N      2026-05-19 06:03:59.126054      \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
adfaff43-f822-4cf9-9e03-d62a0071a716    28f3fbba-d41a-4c88-ad2e-09983513545e    fe065f3b-9eeb-4682-827f-6f2c25743883    26379f79-ec39-45f2-97f8-b60de93f0e25    6e674600-2edd-40b7-a5a5-f0892a73acbf    1.00000 \N      100     2026-05-16      f       \N      2026-05-19 06:04:49.99088       \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
80e2cf50-10e7-403a-96b4-ea393642787b    9db24d66-dd17-4bc7-b792-28ce08cd0462    e151d01f-d544-41aa-9ace-ffc81e3ce21c    6b3a2f08-412d-4c8e-8716-214e91fa8dad    6e674600-2edd-40b7-a5a5-f0892a73acbf    1.00000 \N      100     2026-05-16      f       \N      2026-05-19 06:05:12.061707      \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
a72797d4-9c4d-4403-bba7-a7bc2fc4ce20    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1.00000 \N      300.00  2026-05-18      f       \N      2026-05-19 07:29:32.439391      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
bd748caf-ef94-4e00-9bdd-1b8b28078aea    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1.00000 \N      70.00   2026-05-18      f       \N      2026-05-19 07:29:32.961842      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c6dc662b-5d94-4693-9bc0-b23d903b04be    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    952061b6-9688-4585-96a6-e69b69db106d    0.10000 \N      50.00   2026-05-18      f       \N      2026-05-19 07:29:33.582765      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
daa2e302-d450-4f72-9471-aa43580bd915    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    a46629db-843b-46b3-bd1f-c786a900f21e    0.30000 \N      90.00   2026-05-18      f       \N      2026-05-19 07:29:34.089826      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
4812d35f-344a-4165-9a9e-c36983bd9e54    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    718bbe4d-526c-4be9-a0d8-b25eda4df34f    1.00000 \N      180.00  2026-05-18      f       \N      2026-05-19 07:29:34.597866      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
5c383259-ec32-43da-9383-0296e05aff82    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    292a8fd5-940c-41bc-ab86-358fa13154d0    1.00000 \N      500.00  2026-05-18      f       \N      2026-05-19 07:29:35.153524      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
78d6d0c0-3735-4ff4-b1bd-283989863674    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1.00000 \N      70.00   2026-05-18      f       \N      2026-05-19 07:30:01.055096      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
3c0e7bd5-9639-4e31-b20b-d62d731d30b1    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    a46629db-843b-46b3-bd1f-c786a900f21e    0.30000 \N      90.00   2026-05-18      f       \N      2026-05-19 07:30:01.532233      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
554c615c-1ed9-46be-b32f-fad0cf8d60d4    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    718bbe4d-526c-4be9-a0d8-b25eda4df34f    1.00000 \N      180.00  2026-05-19      f       \N      2026-05-19 07:30:31.538029      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2f0dee78-5d26-4b6d-973b-578715529452    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1.00000 \N      70.00   2026-05-19      f       \N      2026-05-19 07:30:31.979309      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b10f6e42-df9c-48ea-b8b4-beb02fe727b9    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    a46629db-843b-46b3-bd1f-c786a900f21e    0.30000 \N      90.00   2026-05-19      f       \N      2026-05-19 07:30:32.451563      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
bdbbc451-5818-4e42-a344-d373ccf5f712    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    c75a5eab-2131-4e8c-a5c7-5c1ce69c3eec    1.00000 \N      120.00  2026-05-19      f       \N      2026-05-19 07:36:43.991351      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
4a6105a8-adea-4b74-a1a3-ee5f1f7ae101    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    c75a5eab-2131-4e8c-a5c7-5c1ce69c3eec    1.00000 \N      120.00  2026-05-18      f       \N      2026-05-19 07:37:03.042525      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
826373fc-1b4d-43e7-aa88-23e6e82b24dd    44cd7916-a904-4878-a7ed-204b372246aa    a6aa0f45-4b7a-4657-9a53-e80c16232d05    fe89df4f-307e-4a15-9080-56e50739987d    6925ceb6-8f53-4e2b-b1f1-76924af14ef9    1.00000 \N      1030.32 2026-05-19      f       \N      2026-05-19 07:51:53.449866      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
e1437e2b-ff81-4f65-8a1b-17601c673b34    52f2e259-349c-4055-b3de-6bdc4b107345    4fdefbef-e962-49a6-bf13-038702cc3fec    c913f90f-2b84-45de-86fd-2d0ea336bb3d    6069d3b6-f009-4c64-9f6b-2b465729df72    1.00000 \N      340.00  2026-05-18      f       \N      2026-05-19 07:56:39.896585      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
48497c77-2eb7-4d25-8b7f-7545a22d1605    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1.00000 \N      70.00   2026-05-20      f       \N      2026-05-20 06:57:10.689867      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
4038cbbe-4efc-40e4-b5ed-03d21e8aa2dc    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    a46629db-843b-46b3-bd1f-c786a900f21e    0.30000 \N      90.00   2026-05-20      f       \N      2026-05-20 06:57:11.241147      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
f795d29b-2f57-42e8-ab76-5f062fa55d13    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    31a91729-398b-4c5c-81b1-89daf72b7fc5    0.02500 \N      15.60   2026-05-20      f       \N      2026-05-20 06:57:11.711329      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
54dac16f-f213-409a-adb7-6df37f527621    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    718bbe4d-526c-4be9-a0d8-b25eda4df34f    1.00000 \N      180.00  2026-05-20      f       \N      2026-05-20 06:57:12.235127      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
f42768fe-8743-4cd3-9c58-0f25c27627bd    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1.00000 \N      70.00   2026-05-20      f       \N      2026-05-20 07:05:58.969081      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
62d4529e-5d7b-45ca-85bb-12c46baa53f4    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    a46629db-843b-46b3-bd1f-c786a900f21e    0.30000 \N      90.00   2026-05-19      f       \N      2026-05-20 07:05:59.451105      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
6be3d716-a2e6-4bd5-b9f8-f4eb0b8b4c0a    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    c75a5eab-2131-4e8c-a5c7-5c1ce69c3eec    1.00000 \N      120.00  2026-05-19      f       \N      2026-05-20 07:06:33.440276      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
0d8bd4c9-4957-47b8-a458-e2381de0d691    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    40906273-a918-45e5-88ed-9a764ae8f47b    1.00000 \N      552.00  2026-05-29      f       \N      2026-05-30 04:12:52.717078      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
825a9d5a-4418-46bc-b919-cbc2c6f9856d    0a87d9f1-9a42-42e7-8062-52f03d34db3e    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    c0d83349-f24a-4c0e-b08c-b9a8d4eca067    40906273-a918-45e5-88ed-9a764ae8f47b    1.00000 \N      552.00  2026-05-29      f       \N      2026-05-30 04:13:17.743524      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
3ae615b7-131c-4905-94c6-1a318f4e3502    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    cde77c22-7efb-47f5-a23f-62c5e1e32016    1.00000 \N      175.00  2026-05-29      f       \N      2026-05-30 04:16:52.225808      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
e31f36a8-7939-4fd5-b214-ae9c4d24d722    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    1edb2d92-f0d7-428e-8866-951b4dce645f    1.00000 \N      2200.00 2026-05-29      f       \N      2026-05-30 04:16:52.839081      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
101c35b6-c945-4ad0-8f3a-b28bf94e3119    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    9e2ec26d-2c40-42ca-b10a-aa241f21c6bf    1.00000 \N      300.00  2026-05-29      f       \N      2026-05-30 04:16:53.445459      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
569f116b-b169-4716-95ee-4337123da4c4    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    9a92223c-b130-450c-be27-175b5cd20691    0.20000 \N      45.00   2026-05-29      f       \N      2026-05-30 04:16:53.942352      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
054828e0-2acb-4564-bb3a-bd44f5ff6648    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1.00000 \N      70.00   2026-05-29      f       \N      2026-05-30 04:16:54.445577      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
5c1dbf7a-7bf7-4fc7-b52f-15573bf7ede7    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    c52845a1-6209-4f20-a232-2e83c2c522ac    0.15000 \N      90.00   2026-05-29      f       \N      2026-05-30 04:16:55.054074      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
904fa642-c438-401c-88e9-040d756f6672    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    ed293708-601e-46b4-9c35-ff6fada3776b    1.00000 \N      280.00  2026-05-29      f       \N      2026-05-30 04:16:55.557111      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
3ec8583e-44da-4f96-a4be-9ef0f2a5557f    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    ed293708-601e-46b4-9c35-ff6fada3776b    1.00000 \N      280.00  2026-05-29      f       \N      2026-05-30 04:17:18.606213      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
ad764ea4-0668-47fe-a715-ca7c79738a03    bea61a27-3e66-4b09-93a4-c4a9c71ccde3    b98e1c14-1b11-4953-b795-ff41a2042572    99a9b749-b3b1-40ae-98cc-a59a08fdf79f    ed293708-601e-46b4-9c35-ff6fada3776b    1.00000 \N      280.00  2026-05-29      f       \N      2026-05-30 04:18:51.356334      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b55e22f9-8f5d-4778-8909-07eaa4e2e34d    8da786fe-daae-4d48-8e91-8917843fbff0    b98e1c14-1b11-4953-b795-ff41a2042572    09264a61-0b3c-41e3-be12-160077b0e7a3    ed293708-601e-46b4-9c35-ff6fada3776b    1.00000 \N      280.00  2026-05-29      f       \N      2026-05-30 04:19:05.975305      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
acf8126b-97f4-4be5-bf44-b9caf6c15760    3b76bd0b-a589-48e3-b4f4-d1edc8d470c3    b98e1c14-1b11-4953-b795-ff41a2042572    fb57ff0c-df62-4858-abae-cf4ec4e3170c    ed293708-601e-46b4-9c35-ff6fada3776b    1.00000 \N      280.00  2026-05-29      f       \N      2026-05-30 04:19:26.349254      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
b59894a3-246b-4a16-bf26-042401d7aa76    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    ed293708-601e-46b4-9c35-ff6fada3776b    1.00000 \N      280.00  2026-05-29      f       \N      2026-05-30 04:24:22.002519      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
dca77099-6d48-4736-9f52-5b1d99a954b1    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    3bba8890-8f31-4721-a1eb-23b1bc82b540    1.00000 \N      12.50   2026-05-29      f       \N      2026-05-30 04:24:22.570165      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
824fca5a-addb-4b35-90bf-fe744ccf16d4    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    09e5ea1e-bdbd-40c5-bf88-144ac5736c32    0.16667 \N      59.00   2026-05-29      f       \N      2026-05-30 04:24:23.059518      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
d71c0ceb-b50d-4fdf-b493-138fd680f2e1    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    cedb9f41-d4ac-4f56-ab01-33b3d1624ea6    0.08333 \N      16.10   2026-05-29      f       \N      2026-05-30 04:24:23.563937      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
22340fc4-a127-4533-854c-f8e6a79f1f36    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    58ac3468-68be-4292-a89c-e54113afe127    1.00000 \N      180.00  2026-05-29      f       \N      2026-05-30 04:24:24.080001      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
2866cda8-3f07-4cac-8fa1-aee788105cf6    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    71503f5b-25c9-418a-bf39-2c8df2215d2f    1.00000 \N      69.30   2026-05-29      f       \N      2026-05-30 04:25:47.944371      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
7eb0b1fb-5424-416c-8986-f55ab8e0f032    7777790e-5fa9-431b-a7db-fab89730eb7f    05805800-43a9-43e0-837b-16c566ed2767    f93cd1d5-a6c5-4e76-8171-a385f3777783    7de3ded2-98ca-4e41-afaf-347410e44f18    1.00000 \N      125.00  2026-05-22      f       \N      2026-05-30 04:49:40.636228      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
6bba616c-f50a-423d-9c48-17aec5099d28    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    8bdc7827-15b9-4b15-b341-08598255ab11    1.00000 \N      1051.00 2026-05-22      f       \N      2026-05-30 04:51:21.863616      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
eb41381c-93bd-4396-aaff-3a083eb185b1    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    10cb955d-f9ca-4602-a517-9109f89b2dfa    1.00000 \N      250.00  2026-05-20      f       \N      2026-05-30 04:53:48.672382      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
0b6a455d-2692-463e-ab6a-b873f8840b3a    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    0c4f0512-1f65-484c-94b1-8415678a326e    2.00000 \N      700     2026-05-28      f       \N      2026-06-01 06:35:45.305883      \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
3af881e2-532b-4b67-b396-30015247d2dd    e7b9bb69-32d1-4bd6-af0b-361b1ae4d451    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    0ee5fcb6-2aa6-426a-9cf8-ce41f46d4d23    6e674600-2edd-40b7-a5a5-f0892a73acbf    1.00000 \N      300     2026-05-28      f       \N      2026-06-01 06:50:28.636664      \N      2026-05 fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8
64d6ccca-940f-4b1e-ac1c-74b437548c54    cc2fccde-6e0c-4f23-bd3d-b1ec586c4c5c    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      eeb6c0f0-0d1c-44db-bbfb-8b230100d7f6    1.00000 \N      275.00  2026-05-21      f       \N      2026-06-01 08:28:41.413289      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
980bcaca-f9e2-494e-ae1c-50a584b6ec25    ea15f29f-4aa5-43a3-9278-52ed34e73eeb    1e44b508-ea1a-4085-a7d8-91bf6035bfc8    31a83f9d-a6fb-483e-9a85-2289818b6737    66b9958d-cf0c-43a2-b517-a74aacf76647    2.00000 \N      300.00  2026-05-21      f       \N      2026-06-01 08:30:41.129392      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
bed53cbd-bc05-42e7-85a5-3e0b88530c98    ea15f29f-4aa5-43a3-9278-52ed34e73eeb    1e44b508-ea1a-4085-a7d8-91bf6035bfc8    31a83f9d-a6fb-483e-9a85-2289818b6737    76cd6fba-d519-4df9-9cd3-ce99ed8fd0bb    2.00000 \N      350.00  2026-05-21      f       \N      2026-06-01 08:30:41.659989      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
46954efe-a8ae-4215-a9e8-cf08f04b3c8c    cc2fccde-6e0c-4f23-bd3d-b1ec586c4c5c    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      2c697218-914b-4cf1-b92c-2befd2d39b7c    1       \N      425.00  2026-05-21      f       \N      2026-06-01 08:28:40.399549      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
d8919882-8bd0-4c7c-8207-18a3ecbe7107    cc2fccde-6e0c-4f23-bd3d-b1ec586c4c5c    96372285-ae9a-45bb-acbf-95d3447b87bb    \N      d2672769-8460-49f3-8295-2c4857cf01c2    2       \N      300.00  2026-05-21      f       \N      2026-06-01 08:28:40.876205      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
4ff9c3ca-6657-45ff-9e8f-4ea3c8c26f0f    2328687c-cb15-44cd-adde-141b6d283ccb    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    214bd414-650f-480a-86a5-622c698b63d6    76cd6fba-d519-4df9-9cd3-ce99ed8fd0bb    4       \N      700.00  2026-05-21      f       \N      2026-06-01 08:29:34.489067      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
f4d0ed96-7319-4c55-abde-37d33dc9d219    01e81231-bb91-46ef-b8de-4ad8c1c5fe28    3e04bf98-2062-484c-8832-a6ac763fb9ac    ccd96396-4450-4c33-90bd-a32e6a3c2e81    2c697218-914b-4cf1-b92c-2befd2d39b7c    1.00000 \N      425.00  2026-05-21      f       \N      2026-06-01 08:34:31.160676      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
a22c56f3-6f6b-421e-baf5-37f890695ae5    ae00da66-b9fb-4874-93d6-802223ac2c80    8ed90e29-86b0-4cfe-a131-c06cb7413956    383c1069-03c1-4a20-96ce-e89c59cad905    2c697218-914b-4cf1-b92c-2befd2d39b7c    1.00000 \N      425.00  2026-05-21      f       \N      2026-06-01 08:39:14.925045      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
3fd7748f-063d-4e8e-b198-5bde474e857a    fa4ba72a-c067-4cbb-b86a-7e4cf8db638f    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    c65e130b-82df-4aad-9207-ecf941199738    66b9958d-cf0c-43a2-b517-a74aacf76647    4.00000 \N      600.00  2026-05-21      f       \N      2026-06-01 08:39:46.179847      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
63b8ee6e-2480-441b-b0e3-967cfb1f5fe1    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    66b9958d-cf0c-43a2-b517-a74aacf76647    4.00000 \N      600.00  2026-05-21      f       \N      2026-06-01 08:41:30.835381      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
ee4804b4-43f5-4571-b21c-380bd697d2eb    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    ac82737b-0f81-4e1e-a0a3-64310a0fe3ed    1.00000 \N      300.00  2026-05-21      f       \N      2026-06-01 08:41:31.33817       \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
84241a1d-3a57-44b5-a884-e21e05343848    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    d2672769-8460-49f3-8295-2c4857cf01c2    2.00000 \N      300.00  2026-05-21      f       \N      2026-06-01 08:41:31.849379      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
d0222ac5-d6bc-4f81-8b7f-22d3eb312ede    b01f993d-3701-4f15-a873-a7c3b8662689    3a68c9e2-1088-48d4-b3ff-17231f380ecc    2eb22dd0-9df6-44af-8174-3e35ac405704    17de3b72-bbc3-412e-a6d8-0e9afcc70def    1.00000 \N      300.00  2026-05-21      f       \N      2026-06-01 08:43:11.733923      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
2fdb91bb-2897-4c6a-a245-b8885652cb61    265dc87b-8136-4af8-bf84-15cce35a2a08    53188f5a-025a-4154-b876-5e4ae1f220ed    29658560-917c-4df5-8606-bf053689b49a    17de3b72-bbc3-412e-a6d8-0e9afcc70def    1.00000 \N      300.00  2026-05-21      f       \N      2026-06-01 08:43:40.66482       \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
629abb6d-cf90-4b31-8a98-f13731d721f3    370ada88-9266-4154-ae13-35e8726bc871    53188f5a-025a-4154-b876-5e4ae1f220ed    efd99a5d-7cb1-4fe8-a119-83f8b792cb0f    2c697218-914b-4cf1-b92c-2befd2d39b7c    1.00000 \N      425.00  2026-05-21      f       \N      2026-06-01 08:46:17.173363      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
6235df33-3ca1-4f5c-92ab-da22d01d7288    370ada88-9266-4154-ae13-35e8726bc871    53188f5a-025a-4154-b876-5e4ae1f220ed    efd99a5d-7cb1-4fe8-a119-83f8b792cb0f    d2672769-8460-49f3-8295-2c4857cf01c2    2.00000 \N      300.00  2026-05-21      f       \N      2026-06-01 08:46:17.671099      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
6f8a27d1-34bc-4b29-a611-56d4edb40fa8    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    66b9958d-cf0c-43a2-b517-a74aacf76647    4.00000 \N      600.00  2026-05-21      f       \N      2026-06-01 08:47:35.029308      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
617ab804-9668-4f9b-8183-3ac501185ed2    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    d2672769-8460-49f3-8295-2c4857cf01c2    2.00000 \N      300.00  2026-05-21      f       \N      2026-06-01 08:47:35.570168      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
ab6cffa7-8f8d-4717-ad3a-c7a4528e333d    7a443e5b-439e-406d-9071-7cb8bad8f55d    4939968f-1b46-4d2b-83ed-7c1a29806579    07f4f82d-42f5-46b0-b293-ecfc732178c8    2c697218-914b-4cf1-b92c-2befd2d39b7c    1.00000 \N      425.00  2026-05-21      f       \N      2026-06-01 08:48:10.899633      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
53626801-14ca-4339-a385-64e553d9ab2c    fa4ba72a-c067-4cbb-b86a-7e4cf8db638f    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    c65e130b-82df-4aad-9207-ecf941199738    66b9958d-cf0c-43a2-b517-a74aacf76647    4       \N      600.00  2026-05-21      f       \N      2026-06-01 08:48:44.420525      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
d2f3f863-8322-4065-a083-c93ed5b53546    7777790e-5fa9-431b-a7db-fab89730eb7f    05805800-43a9-43e0-837b-16c566ed2767    f93cd1d5-a6c5-4e76-8171-a385f3777783    17de3b72-bbc3-412e-a6d8-0e9afcc70def    1.00000 \N      300.00  2026-05-21      f       \N      2026-06-01 08:51:15.116235      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
f6648681-1ae2-447f-b027-93d8106b0cd9    579743ae-5195-4dca-9aae-ac0f5e9c999b    05805800-43a9-43e0-837b-16c566ed2767    71c19df3-c323-4213-a8fa-5b5747689085    2c697218-914b-4cf1-b92c-2befd2d39b7c    1.00000 \N      425.00  2026-05-21      f       \N      2026-06-01 08:52:01.404785      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
7908028a-6e31-41da-b56b-40a7578887a6    b22b322c-6035-4697-9309-c8a279786522    369d0d0f-5c75-422f-b983-695a04a7f883    c38baf65-24a8-48a8-b5d9-0b51962718c5    2c697218-914b-4cf1-b92c-2befd2d39b7c    1.00000 \N      425.00  2026-05-21      f       \N      2026-06-01 08:52:29.076495      \N      2026-05 50714bb1-7f0e-4363-b470-1c7af22870d4
271e8753-7df8-4314-b4d9-d69d387c7f44    fd1cbc9e-abe5-446c-bef0-ebd171304d49    dbfc0a19-eb4d-4b1e-8c17-0fbc116e8491    \N      4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1.00000 \N      300.00  2026-05-26      f       \N      2026-06-01 09:32:27.791822      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c00a19a5-e5bc-4a21-819c-958174504fe6    fd1cbc9e-abe5-446c-bef0-ebd171304d49    dbfc0a19-eb4d-4b1e-8c17-0fbc116e8491    \N      612e5ad2-02ab-4994-9a3d-b056503c561c    1.00000 \N      250.00  2026-05-26      f       \N      2026-06-01 09:32:28.419196      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
c1d05498-a953-4178-ba0f-b9316a4c64d3    fd1cbc9e-abe5-446c-bef0-ebd171304d49    dbfc0a19-eb4d-4b1e-8c17-0fbc116e8491    \N      c75a5eab-2131-4e8c-a5c7-5c1ce69c3eec    1.00000 \N      120.00  2026-05-29      f       \N      2026-06-01 09:33:35.512809      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
1b972918-d32d-4149-a8dd-d5dc0e4450ef    fd1cbc9e-abe5-446c-bef0-ebd171304d49    dbfc0a19-eb4d-4b1e-8c17-0fbc116e8491    \N      612e5ad2-02ab-4994-9a3d-b056503c561c    1.00000 \N      250.00  2026-05-29      f       \N      2026-06-01 09:33:35.987182      \N      2026-05 3823058b-4ef5-4c22-913f-9cd149cbb6e0
\.


--
-- Data for Name: boxes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.boxes (id, name, type, stable_id, status, netsuite_id) FROM stdin;
c2e10b2e-d645-4752-9bf5-a704453047ef    SB002-S001      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  77
706522da-797c-49d3-918c-891db403993c    SB002-S002      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  78
f3ea3726-2d36-4112-8a3f-a14973c47106    SB002-S003      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  79
ca2da968-1d13-40a6-9ce9-80a3451cc0b5    SB002-S004      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  80
14bd38b2-cc6d-45cd-a8ec-7e619ae363c9    SB002-S005      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  81
88db7ecb-cfb3-407b-b149-0dd7de29f641    SB002-S006      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  82
85489880-a902-46e7-b9ce-47a7b87c0e55    SB002-S007      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  83
715646b2-6870-49eb-a9f4-fc55f21db630    SB002-S008      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  84
1d3b9632-116a-4cd9-9a0f-6af24740d36d    SB002-S009      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  85
e14cb4f7-02d5-4417-adb0-78cb5caa71f1    SB002-S010      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  86
3be807e9-0a9c-419a-8710-f323e5d82ba1    SB002-S011      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  87
9e6d419d-be37-4418-92cc-33b2e3db17dd    SB002-S012      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  88
29c5b8f1-0be9-4369-8404-7a1f828d9f7e    SB002-S013      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  89
cc6a5f4f-2ac1-42f0-a0c1-04c54413571a    SB002-S014      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  90
b10d2896-646e-498e-af78-c8b13b1c5fd3    SB002-S015      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  91
b60db2ad-d999-456d-b56d-b0e210f0c250    SB002-S016      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  92
db44b2dc-291f-4053-b285-daf9342bdb16    SB002-S017      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  93
26ea949a-8ce1-4ddf-9e0b-4bd6567aab2f    SB002-S018      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  94
6f0b6748-5c51-4100-9b64-66058ab10ebb    SB002-S019      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  95
dc14613f-a5d7-4be4-b952-c9a058f19ad7    SB002-S020      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  96
6de10c03-eee8-431d-9886-c5dc5b98efef    SB002-S021      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  97
bdfc656c-12c5-4858-8ba1-c7b108b17e2e    SB002-S022      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  98
74bb3a04-592e-4f25-a9ec-0511d1e2a8ee    SB002-S023      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  99
ffa87a9b-1596-4f69-99d5-5b8cc6b01487    SB002-S024      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  100
b129d22c-4c07-4090-830b-9ccd8cea6cd2    SB002-S025      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  101
ded1129f-2091-4e7e-b655-e86ba6501e45    SB002-S026      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  102
13009090-2ea8-4cd6-a070-6f86e789ddc0    SB002-S027      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  103
a80814fa-d452-4428-a3da-7fdf5163b0f1    SB002-S028      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  104
de282b0d-5fbe-4ea2-b402-814d1f9b1a39    SB002-S029      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  105
b92a389e-84ce-4698-a547-506d0b6eb7d5    SB002-S030      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  106
890410e0-e08b-4b50-acf1-722e3689f566    SB002-S031      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  107
da79a244-bc94-4497-8c03-4fd84f028b6b    SB002-S032      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  108
eb6035c9-e416-4d1d-a76b-96ca68ea5e2d    SB002-S033      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  109
513e6d4a-7dd8-4430-8b5a-f60f305da19f    SB002-S034      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  110
bea81e77-b3b2-4f51-bccc-a205b0ef1d3b    SB002-S035      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  111
cd23bd11-d682-4018-8d8d-469929891b2a    SB002-S036      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  112
ffac5902-fe2f-435d-8487-fd9dee136dda    SB002-S037      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  113
f187473e-04a7-4e38-ab67-1a9089b27270    SB002-S038      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  114
65297e5e-6f0c-4679-bc90-f77205b88e9f    SB002-S039      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  115
940ce4e7-bde8-4180-bfd5-4616b6cc9679    SB002-S040      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  116
cc285778-b716-4c19-9fd1-b938b97ace63    SB002-S041      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  117
1d1bee69-3040-4551-83fc-2e0824779e61    SB002-S042      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  118
3406ef48-3fa5-489a-b422-115cd514bdf1    SB002-S043      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  119
a9f49b28-fd08-4c9f-8455-300e6d86963d    SB002-S044      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  120
46aa0262-f8e5-4595-b558-7ab4c1abdf61    SB002-S045      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  121
d2ca6e4d-e86a-45d0-9ef0-70e63f0fe65c    SB002-S046      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  122
bbeef4fc-b1e6-4977-98c5-420d84869653    SB002-S047      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  123
1f222285-3e81-44ed-8cee-2e31e1e47a97    SB002-S048      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  124
08c28d47-9061-40ad-9dd6-b8a97c2e885a    SB002-S049      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  125
b599127a-3545-4e8c-9a02-c6e0a8a9a021    SB002-S050      Boxes   83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  126
9b224df3-55f5-4748-8a5c-b7fd830f2405    SB002-T001      Tacking Room    83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  127
2b459dc4-38e0-4b41-81d7-a0cbd6bfc458    SB002-T002      Tacking Room    83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  128
9007a21a-991e-4c32-b9ee-5c48aa82f78f    SB002-T003      Tacking Room    83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  129
7965e122-743c-43af-8430-773c8f54842a    SB002-T004      Tacking Room    83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  130
ec57c4ea-ae40-4601-b598-2130bd8a5f81    SB002-T005      Tacking Room    83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  131
08b12bc6-9062-4b4a-a44c-bf7d50228159    SB002-T006      Tacking Room    83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  132
4a9124fb-143f-491d-bf48-8328468a48ab    SB002-T007      Tacking Room    83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  133
7931589c-a3c8-41fb-be3e-6de28ea8ab69    SB002-T008      Tacking Room    83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  134
44f4b7d6-e6b6-479b-adae-79eb678a3cee    SB002-T009      Tacking Room    83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  135
6d5e9894-005c-4a18-82df-cc5f0fff6ff1    SB002-T010      Tacking Room    83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    active  136
c2210c19-cee9-4e94-8126-03a399249ebf    SB001-S001      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  17
ea9b80fb-7a90-4223-b33b-7b79bf0256a5    SB001-S002      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  18
afa6afc6-3dcb-4dc4-bf5f-290ed1ef44c8    SB001-S003      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  19
ea0ac33a-7727-4835-8b19-143a7e6bd56c    SB001-S004      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  20
b4d357fd-5b04-4378-b379-9f1632d96143    SB001-S005      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  21
53662acc-b1ed-4158-887e-5234d928404b    SB001-S006      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  22
c913f90f-2b84-45de-86fd-2d0ea336bb3d    SB001-S007      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  23
08dfae91-b9cd-452b-b102-2baa08b36165    SB001-S008      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  24
27d39b5b-c47c-44a4-903e-5a01f8e181e9    SB001-S009      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  25
3f066c5b-242f-454e-8972-1e7e618a380b    SB001-S010      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  26
c0d83349-f24a-4c0e-b08c-b9a8d4eca067    SB001-S011      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  27
f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    SB001-S012      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  28
2eb22dd0-9df6-44af-8174-3e35ac405704    SB001-S013      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  29
5da98fb2-8983-4ea1-a7cb-ca84578a2b47    SB001-S014      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  30
7282059a-1968-4468-9ed3-b20526f10ee7    SB001-S015      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  31
bb158191-656b-42f4-bb9d-af282193aee3    SB001-S016      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  32
8608c09e-7c7b-4298-a828-aa5e54a9aa9a    SB001-S017      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  33
d1e0d953-04b6-4787-9de3-ed0379f4b00f    SB001-S018      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  34
fe89df4f-307e-4a15-9080-56e50739987d    SB001-S019      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  35
7c908420-ac2d-48ea-95da-0305f7529e64    SB001-S020      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  36
07f4f82d-42f5-46b0-b293-ecfc732178c8    SB001-S021      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  37
6b3a2f08-412d-4c8e-8716-214e91fa8dad    SB001-S022      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  38
f719dd6b-4a6e-4344-9018-02d2ca8267f0    SB001-S023      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  39
1a07b38b-dd8a-436d-acd9-c187de153ac0    SB001-S024      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  40
2732f6f6-5e0b-4231-8a5f-d9baaeb411e3    SB001-S025      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  41
fc59e00d-7f34-4dbf-9e22-f5d201ca748f    SB001-S026      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  42
dd15bef2-8ae0-4f37-a97b-5e6267616863    SB001-S027      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  43
490f009a-d7b4-421b-8c9b-a052ead040a9    SB001-S028      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  44
9d7e3d1f-744f-4326-a236-1d1f0dc4ab15    SB001-S029      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  45
381e7902-95aa-460c-ac0c-2fa03883c20e    SB001-S030      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  46
9d0d7f8d-28e6-408a-a53b-35d285debb35    SB001-S031      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  47
182662c3-e01a-4885-8db8-bde32aaaaa18    SB001-S032      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  48
b90bead8-11d0-4782-8147-537cd223d21d    SB001-S033      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  49
e26c7447-d6a7-4f97-9fed-863110a73d89    SB001-S034      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  50
29658560-917c-4df5-8606-bf053689b49a    SB001-S035      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  51
663359b9-d623-482e-9b8c-330ea9c617d1    SB001-S036      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  52
efd99a5d-7cb1-4fe8-a119-83f8b792cb0f    SB001-S037      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  53
6d0af39f-9319-4174-91c1-e546f553e2a2    SB001-S038      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  54
b1c71e70-c705-4779-bff3-d8ab0bf231f4    SB001-S039      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  55
6a8b068d-9544-4486-b976-3b360a04e42f    SB001-S040      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  56
dd80eaa8-0d46-4c1c-94bc-84b3103406f2    SB001-S041      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  57
fd088d87-96f7-442c-8fe3-9e7175b506be    SB001-S042      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  58
9ead1266-5a16-440f-9816-965061849531    SB001-S043      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  59
c452d6bb-850d-4be7-bd06-d1b4f0799981    SB001-S044      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  60
5fe9e3b0-6bf4-48ee-aea0-ad0723edbbd3    SB001-S045      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  61
26379f79-ec39-45f2-97f8-b60de93f0e25    SB001-S046      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  62
c38baf65-24a8-48a8-b5d9-0b51962718c5    SB001-S047      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  63
5b1b3a5a-6f46-4bf6-8ffb-eb7b887c0153    SB001-S048      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  64
bfdaa14a-0158-4eae-9acf-7f58d4b99863    SB001-S049      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  65
cb6a2ab2-ee83-4b90-a3d2-c8a6ac6a55fa    SB001-S050      Boxes   9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  66
bf39524e-d84b-441b-a81c-484592bd93ae    SB001-T001      Tacking Room    9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  67
e018c12b-08d4-4963-8bf8-f25a7be68c36    SB001-T002      Tacking Room    9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  68
8bcc32c7-66e0-4660-9925-e109ee79b146    SB001-T003      Tacking Room    9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  69
6f4d1549-0969-448e-b873-99e1cfd164b7    SB001-T004      Tacking Room    9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  70
44eafb9a-4fa0-4e79-9127-7ea593955bb6    SB001-T005      Tacking Room    9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  71
832d8cad-f613-40c1-b9c4-596dd32a2d07    SB001-T006      Tacking Room    9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  72
aacc87da-399d-4c64-aeab-519c131bf367    SB001-T007      Tacking Room    9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  73
95b882bc-72ea-41e7-8566-ebe00a239534    SB001-T008      Tacking Room    9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  74
501804cd-1609-4e32-b761-92acbb7d40fd    SB001-T009      Tacking Room    9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  75
087eb547-466c-42f5-b437-e77371edeaa3    SB001-T010      Tacking Room    9bf0a6da-104a-4477-b16a-8dc7c09ad751    active  76
67e6b70a-d504-451b-a0b0-fa4072aaaf16    SB003-S001      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  137
c65e130b-82df-4aad-9207-ecf941199738    SB003-S002      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  138
7a08de89-a9f5-4dd5-8b1a-6ce585b57e76    SB003-S003      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  139
51f2090e-54fe-4c1a-82d2-b81b5b883dbf    SB003-S004      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  140
2a5d586a-b056-44cf-8cd1-a35b634adcdd    SB003-S005      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  141
a6b06986-d142-4366-90dc-64f5ab23ab78    SB003-S006      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  142
383c1069-03c1-4a20-96ce-e89c59cad905    SB003-S007      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  143
2c08a20d-51ff-4b1d-8871-7e2ec0b65568    SB003-S008      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  144
c305222c-ef2c-4cac-a860-53617169f789    SB003-S009      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  145
0ee5fcb6-2aa6-426a-9cf8-ce41f46d4d23    SB003-S010      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  146
58a9a059-169b-4060-88e3-bfef2e5593b6    SB003-S011      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  147
da0ab2eb-ca08-4958-a03f-7540f884c56b    SB003-S012      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  148
d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    SB003-S013      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  149
f3b85547-5092-4f72-bf25-b65a010c58fd    SB003-S014      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  150
b0cf9824-3634-4b33-aba1-0990e8cc240f    SB003-S015      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  151
31a83f9d-a6fb-483e-9a85-2289818b6737    SB003-S016      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  152
d3e34213-0133-4b50-b5ab-70003980350a    SB003-S017      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  153
ea18dd2c-50c7-45b6-b36e-df0f5a847518    SB003-S018      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  154
ccd96396-4450-4c33-90bd-a32e6a3c2e81    SB003-S019      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  155
306983c9-0076-404d-885b-42f1801cfa88    SB003-S020      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  156
77f8ca14-adb8-41ec-94f8-704fc6018774    SB003-S021      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  157
eeef71f9-3da4-4028-a349-7688735b2f7e    SB003-S022      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  158
3a3b776f-c4c9-471b-ba2a-136fdb7fd98d    SB003-S023      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  159
715087dc-9a65-42de-b107-5ebcf9f0ffce    SB003-S024      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  160
7842c10d-d9af-4a31-bcb1-c3991a8644ba    SB003-S025      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  161
71c19df3-c323-4213-a8fa-5b5747689085    SB003-S026      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  162
f93cd1d5-a6c5-4e76-8171-a385f3777783    SB003-S027      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  163
45b62723-ef71-4f5d-ab82-8336bfd474a6    SB003-S028      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  164
6625d0ce-ca82-4373-9ceb-434a68a31602    SB003-S029      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  165
58b4eaa8-998a-433d-a88a-cebbab32e2e9    SB003-S030      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  166
a8a93b57-561d-4432-bba8-7c9bc8326ee2    SB003-S031      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  167
ea3d6601-2949-4533-9e49-55c585e7d5f1    SB003-S032      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  168
286ddcad-9db6-4b76-9e14-b96bb403493a    SB003-S033      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  169
c6e77b87-6119-4743-81a3-c10f648599dc    SB003-S034      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  170
87d14a58-9edb-410d-9ac0-80f01a04f761    SB003-S035      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  171
3cead808-232f-4d8a-926f-f3c84c731211    SB003-S036      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  172
3bae3844-10d8-4140-b2fb-468b35bd5640    SB003-S037      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  173
cf2395f2-80d5-46cc-b770-45a05f0f8583    SB003-S038      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  174
596ce3b8-9c3b-410c-9385-87d1388e78dc    SB003-S039      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  175
a5fefae2-ca4b-4f1a-b359-18653f57a039    SB003-S040      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  176
201edc18-e979-4795-9396-e11f7a579347    SB003-S041      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  177
f231df6c-a72f-433a-b5ca-a88981152eee    SB003-S042      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  178
3c790387-76fc-4fd1-893d-884498cbd8da    SB003-S043      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  179
1a74eb4c-4815-4721-824d-4d0443fe307e    SB003-S044      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  180
5fb2de9e-1363-42ac-93e7-8504fb0062fd    SB003-S045      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  181
2d9bf537-4771-4e91-ad5f-c67e9178d69c    SB003-S046      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  182
06405660-ee33-4a64-a126-b6e072ee6e7c    SB003-S047      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  183
728c2e50-8cfb-4748-bc40-b5e9964c4d1e    SB003-S048      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  184
abe52432-2218-48a9-87fb-aeefd89e82a2    SB003-S049      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  185
214bd414-650f-480a-86a5-622c698b63d6    SB003-S050      Boxes   ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  186
cefb6194-9430-4fe4-aae5-5af091daea26    SB003-T001      Tacking Room    ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  187
d12e5fc5-a002-4883-a75b-e20bbdf9b132    SB003-T002      Tacking Room    ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  188
b6759118-3443-4b2d-91a9-51e308f99e48    SB003-T003      Tacking Room    ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  189
d808e9e7-780e-4bab-8056-eab517e5edcd    SB003-T004      Tacking Room    ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  190
619f2603-5643-4afd-8e7e-d441afe38cc1    SB003-T005      Tacking Room    ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  191
27ea6791-8577-4105-9e97-f554200efc4b    SB003-T006      Tacking Room    ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  192
9a442a5c-cbf0-451b-8516-29065004ccab    SB003-T007      Tacking Room    ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  193
5ffbc257-eb85-4f9c-8301-8204edfbae31    SB003-T008      Tacking Room    ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  194
bdf3051f-cf95-4206-9a14-5f6bdac5568b    SB003-T009      Tacking Room    ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  195
61acb9c5-9395-4094-89ac-f7a97c6f2893    SB003-T010      Tacking Room    ac756abd-1920-4fd5-8e2f-ec2bd9965361    active  196
33eb4c02-3134-46d3-a795-d9c7eeb94aed    SB007-T001      Tacking Room    1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  339
4a4f8a73-a5cc-42a5-9905-e674bb7743cd    SB007-S027      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  335
e8483047-9c30-4a53-b220-9a78857f4515    SB007-S003      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  311
2c0de421-46ba-4752-9964-4c3485f7af3d    SB007-S022      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  330
e36507e6-3b23-40fa-bd37-9b1f5733bd67    SB007-S021      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  329
e6455147-0685-41b6-a5d8-10cc057da702    SB007-S029      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  337
ca2a507c-e49d-4192-a380-773fa7d4be98    SB007-S028      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  336
2e4483b1-390e-4d71-b6ba-4af8ba42c54d    SB007-S002      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  310
493d93c8-a206-4b84-a565-31ce54fb3031    SB007-S004      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  312
309b9698-8027-4d80-b1c5-421e991b00ea    SB007-S025      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  333
e6ca296b-f4e3-4a24-81ed-53b87916b1cc    SB007-S030      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  338
a2d6ca75-29a4-47af-af43-8831d2195de1    SB007-S026      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  334
69586cff-3ee8-4e16-b2d2-6ad25d0b1e07    SB007-S016      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  324
ad9cbdd7-2b2d-4216-a72f-0d97df8711a6    SB007-S024      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  332
71fd0e42-27a2-4afb-8e0a-c8b04622aa98    SB007-S017      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  325
46f98f04-83c1-4450-bb2d-4dee38323d43    SB007-S020      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  328
7098cbcc-a221-41ad-8e91-988faf8fcfbd    SB007-S018      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  326
3af0155c-2062-4abd-94db-d704834e17b3    SB007-S015      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  323
a646641d-afe4-45c1-a126-1190cfc13fc1    SB007-S001      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  309
708b433b-9f03-4917-8792-641bd66d69dd    SB007-S023      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  331
581a6529-ffc4-4cba-a402-092d4bcc6d82    SB007-S011      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  319
4eeaf4fc-5940-444c-9b0b-d963ebfbe1b3    SB007-S019      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  327
232b7724-2f12-4851-b182-1ce869254f97    SB007-S013      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  321
1623057d-8e10-4f12-ab30-3bcd8bbdc39e    SB007-S014      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  322
2e93ce6d-576d-4910-a41e-fd46a3ac5122    SB007-S012      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  320
561b1cd4-77d3-4e38-a429-e9e0d3b31ea6    SB007-S010      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  318
00816da0-10b1-4c26-aa49-9a1befba5d79    SB007-S009      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  317
5f6dc31a-4b43-4a0b-b6fe-5839d176b1f4    SB007-S007      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  315
a7e3dd6e-65ab-4bcb-bddd-82d58b06709a    SB007-S008      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  316
5d2746c7-60e3-4849-96d3-5f74a452a69c    SB007-S005      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  313
7aa74b71-dba2-4ae9-b751-3929468bc629    SB007-S006      Boxes   1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    active  314
7e40f1c0-edf6-42ff-914e-b29fcdb2e902    SB008-S001      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  340
fa11acff-fc2f-4bd4-a0d9-27d3e42c9206    SB008-S002      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  341
a5d3191e-f717-4530-86ec-39fb9ac2f418    SB008-S003      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  342
ae496bc3-fce5-4c13-9767-23bb163b6ffd    SB008-S004      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  343
cdf51075-232f-41bd-9fa3-62bab6abddc2    SB008-S005      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  344
dd18500b-1eea-4421-b241-761a79f17d10    SB008-S006      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  345
be11c1c4-e965-419f-a8d6-3741b71e069f    SB008-S007      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  346
70919031-eb2a-4755-b59b-777d513caa22    SB008-S008      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  347
5740551c-db04-42b7-956f-b1f306338232    SB008-S009      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  348
621ec835-4df4-4098-b197-56ecb36d7ccd    SB008-S010      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  349
33a134e4-a532-418f-9c39-9678781797d1    SB008-S011      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  350
b7d1edcc-7e87-4136-a56d-143c1f4cf51f    SB008-S012      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  351
6280e979-7e86-434a-ae92-7d729b5c13fd    SB008-S013      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  352
c5d96149-a7ae-44fb-9eb9-73821855785e    SB008-S014      Boxes   5023547e-1af7-4840-a647-bf8b216156f9    active  353
da363cdc-0775-46ca-88c5-b55c1f4bad75    SB008-T001      Tacking Room    5023547e-1af7-4840-a647-bf8b216156f9    active  354
6cae03f2-1d84-4b8f-b009-73db7d44bb3c    SB011-S001      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  385
2034de32-cd5c-4a94-a75a-92c9cc0b9633    SB011-S002      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  386
40405bf6-c55e-4efb-a6bf-4c3ff8fe20bf    SB011-S003      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  387
7c6a8f8d-6cb7-456c-83d1-b832c50f1084    SB011-S004      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  388
10be0749-a697-44e4-ad0c-385b17466235    SB009-S006      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  360
f440c757-3cde-4369-8e29-6cbc28d21408    SB009-S007      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  361
a3220d80-6974-482b-9105-c4842847cc30    SB009-S003      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  357
bbe42c5c-44f7-415c-8263-b0dffdd4f0b7    SB009-S004      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  358
5d76540a-9d1f-4741-a020-6510848880bc    SB009-T001      Tacking Room    c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  369
c3964a46-7b7b-4800-ac0e-aaa10532f2b1    SB010-S010      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  379
74de0353-ac42-44ee-a04e-75a8b161ed57    SB010-S012      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  381
648ab756-7bf5-4b33-a5f0-99affb996cc6    SB010-S002      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  371
8bcc6eee-1a6b-4599-82d9-c0c0917171d9    SB010-T001      Tacking Room    bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  384
8ee13dfe-b33c-41b1-9c48-0a65ac24ef1c    SB010-S004      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  373
00f2beeb-9f7b-402b-b0c0-f946c2f475c0    SB010-S007      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  376
60110d36-3091-4121-afdc-0f8cdacc3ba8    SB010-S011      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  380
78697342-a213-4503-97b9-a103575da23e    SB010-S005      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  374
b8b9a670-051f-4dae-b1bd-3c73de945e7e    SB010-S013      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  382
4943b5bd-597b-43ce-8d48-eaeb755046cf    SB010-S014      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  383
48a47995-5bee-4f06-b279-9d959180e164    SB010-S001      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  370
7edfdd35-db22-47e4-8ce9-36a0368b9761    SB010-S003      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  372
4cc466b7-095f-44a7-98ab-7cdbc36cbbef    SB010-S006      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  375
4b1a7f9f-d392-436f-ba05-12ae7df6a9fd    SB010-S008      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  377
f8c80191-d634-40ef-95f6-a1f466e58e68    SB010-S009      Boxes   bacdd040-4e44-4b97-81dc-c22fbd3e0d82    active  378
06da8b10-458d-4c11-aa38-872689bea15b    SB011-S005      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  389
a986c71a-a81c-4485-b552-f51a4a191e91    SB011-S006      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  390
ddf679e0-1420-4b2b-abb3-b35a4006f666    SB011-S007      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  391
1630bedb-980f-46f1-b535-1fdb76678e08    SB011-S008      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  392
6fac106b-3261-4008-9c9f-b50a4d0a1034    SB011-S009      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  393
9a34af86-c830-428c-abc7-7f2be681c76e    SB011-S010      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  394
44d63e3a-67b3-462f-8ae8-2e0053d68fb4    SB011-S011      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  395
a55faebe-319d-4832-a4f2-67ab4bcb6cd4    SB011-S012      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  396
627fa5ae-ebb4-4eee-a98e-2c3785155ba8    SB011-S013      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  397
6afcb024-f3d7-499a-afe8-e440feccc728    SB011-S014      Boxes   f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  398
6a19459a-7fc4-4f31-a37a-4b3c847b5f0e    SB011-T001      Tacking Room    f0b9f500-073f-45c8-bd8c-0852ccbedb3d    active  399
e47951f9-864f-4927-8ae0-fd7dec0cffca    SB009-S009      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  363
52dcf541-eff5-466d-b747-d3c8de38752f    SB009-S001      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  355
92f29da3-7cd5-4fed-913f-8741be7b6b72    SB009-S010      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  364
8fdfd25b-1c76-425e-94c4-9353a6ef78bc    SB009-S012      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  366
662c361e-5cf2-4d0b-bcbe-568d3f15a574    SB009-S013      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  367
ef239cc8-c9bd-4088-8d87-df3e4ecacce5    SB009-S014      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  368
1f6d6eec-cf0b-45eb-8eaa-95b6d3a253a3    SB009-S002      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  356
7a5bf935-b80e-4e5b-9a6c-2ad49c28a2b9    SB009-S005      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  359
5b802773-a084-4526-938a-3f21c4640ffe    SB009-S008      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  362
f86d52df-6b82-4a1c-b0d4-5b96581cc29f    SB009-S011      Boxes   c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    active  365
d40cc697-3f03-49fb-8be8-827e3080dafb    SB012-S001      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  400
d03520fa-61cf-44c9-86e2-0f1aed47d069    SB012-S002      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  401
4be356ad-7a17-47c9-9a9d-a75647fcb9bf    SB012-S003      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  402
fb57ff0c-df62-4858-abae-cf4ec4e3170c    SB012-S004      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  403
99a9b749-b3b1-40ae-98cc-a59a08fdf79f    SB012-S005      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  404
f1c38418-c8c0-4483-bf87-a851e13619aa    SB012-S006      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  405
a7343d80-4e98-46d9-ab0f-07144fa6536b    SB012-S007      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  406
09f090e7-ac3f-4d93-937e-67f278361a0d    SB012-S008      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  407
4beea112-21e6-4b90-8574-e8923d744ee3    SB012-S009      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  408
f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    SB012-S010      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  409
09264a61-0b3c-41e3-be12-160077b0e7a3    SB012-S011      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  410
830babf1-8dbb-4061-8a4a-c44797d113af    SB012-S012      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  411
264918b9-4216-4a40-a611-72f0277ce867    SB012-S013      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  412
d055ad88-b4e9-430e-936e-d7ffff33578e    SB012-S014      Boxes   4d6524dd-0e9f-44f9-8222-132ef9408f75    active  413
b5ec2f44-8b5d-418a-a404-c9e4df630851    SB012-T001      Tacking Room    4d6524dd-0e9f-44f9-8222-132ef9408f75    active  414
61714c26-9d0e-4121-a7bb-dd6be010f0f8    SB013-S001      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  415
2993867c-9f8a-4510-a5c3-cef0513716bf    SB013-S002      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  416
677517c3-32b3-455c-ab16-f48bce43e8a7    SB013-S003      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  417
59036a92-6f30-4bcc-92b6-306a311d7717    SB013-S004      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  418
85f59a2c-03f0-4aa3-b466-be49c4b41ff7    SB013-S005      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  419
2ea73052-7fcf-4969-9e92-ec62c886766b    SB013-S006      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  420
fff662d2-7313-45d5-97d5-de1912749f45    SB013-S007      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  421
0d91b8b9-6d4a-448a-aaa0-833334e4f1ac    SB013-S008      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  422
8112400e-6837-4691-8799-14255dec2e75    SB013-S009      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  423
d49a7863-d73f-4079-aa1b-1d3de3b602a6    SB013-S010      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  424
e0bae9b5-b88b-4052-a57a-06c0a3b670c7    SB013-S011      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  425
56d4dfed-ffd2-4e62-8e83-76bc3cdbeaa4    SB013-S012      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  426
0893c75e-ead7-47e9-a8de-d315cf0ecd2e    SB013-S013      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  427
97a76d48-f86e-4aa8-a028-1d1a03befb16    SB013-S014      Boxes   12deffac-f07e-4eae-8f26-516a007733a4    active  428
eef6c678-e1ed-4145-9756-4a513efa41b7    SB013-T001      Tacking Room    12deffac-f07e-4eae-8f26-516a007733a4    active  429
94826325-f9fc-4467-b139-9bb63bb09703    SB013-S001      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  415
198cd372-7e0f-42dc-b87d-705a59805287    SB013-S002      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  416
cf96856d-3fb1-4514-890b-76e381593a3f    SB013-S003      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  417
ba8ef8d0-ac65-44be-a7d5-2fa3c4d52f77    SB013-S004      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  418
14b30bb3-366e-49c3-9d78-bd26d62ea8e9    SB013-S005      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  419
af7430ff-a5a4-424f-a4f2-3b45f26ac194    SB013-S006      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  420
212f947a-f8cf-4296-af58-6c5b78d78018    SB013-S007      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  421
42bb84b3-a514-4df8-9519-5650be1057e1    SB013-S008      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  422
f3a509a1-de55-43b2-b580-cd99824d3917    SB013-S009      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  423
9c8341b2-fe92-49e7-bd94-4cf531b99824    SB013-S010      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  424
166199b4-844c-4782-beea-2c176eeb28f8    SB013-S011      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  425
f501a1a4-5fb8-40ef-9def-bf021890eb41    SB013-S012      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  426
d94bee47-3db8-446b-a96a-4b29d331a2e5    SB013-S013      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  427
ba976d3c-81f4-4dc3-abdd-0ada87a1bdf8    SB013-S014      Boxes   b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  428
5976e3ed-62f5-42e7-bf94-d79170108414    SB013-T001      Tacking Room    b39ef8a2-5b12-4e84-ae4c-0647abb768e2    active  429
6fe69379-4923-4e0f-abf1-3f193b8f79d8    SB015-S001      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  445
043132e4-95c5-42e9-a2f9-dbaa3f30f1c2    SB015-S002      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  446
dcce87ee-6acd-442c-831c-7481a1396448    SB015-S003      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  447
1fcf0a42-ec8f-4925-af91-1191bcd3f754    SB015-S004      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  448
8bfb112a-750d-4889-9c8b-c469ec8b5d97    SB015-S005      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  449
521630c4-6c28-491d-8bb5-3c7127dad631    SB015-S006      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  450
f9aa5f62-ae6a-4b00-a0ca-10f6c0b543e1    SB015-S007      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  451
55f59b08-bdf4-46bb-bd10-ba66671d8ac8    SB015-S008      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  452
95572b90-a69d-4b99-9029-feb70ee961f9    SB015-S009      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  453
e67c3f08-9c1c-4535-8be2-f9486e52c123    SB015-S010      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  454
a9022da1-1e88-4126-b5f3-65e87af0cb99    SB015-S011      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  455
6997571f-fad4-496d-a611-b3410bf7f890    SB015-S012      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  456
c7862bdc-1df9-4b7d-990b-8f78b22195f5    SB015-S013      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  457
8cc33fe4-6828-4f71-a15f-16d3dba4c2d9    SB015-S014      Boxes   36748823-6554-4f94-8833-19220605bdb8    active  458
646998ab-9881-49ba-8f39-0d481a0ef255    SB015-T001      Tacking Room    36748823-6554-4f94-8833-19220605bdb8    active  459
5dd5bbbd-130e-4200-94f2-4809821de71c    SB016-S001      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  460
25437b87-12c1-4787-a099-0a879d05681d    SB016-S002      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  461
9a5c24b2-f404-4888-9b9c-3fb2390fd72f    SB016-S003      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  462
acc01a70-307d-4eb8-bdd4-ce3ee32bac0f    SB016-S004      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  463
68d67879-0c06-4afb-baa7-dea46c04a84f    SB016-S005      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  464
56ed88b4-7d0b-4b6f-8dd0-ea1a9abc14fb    SB016-S006      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  465
4dcc79ab-8547-49c6-9958-dd43eb08263c    SB016-S007      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  466
42e4d30d-c200-4453-9376-d51ed7479fe8    SB016-S008      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  467
f091d084-f186-48fe-9d26-c42ff01e5024    SB016-S009      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  468
1422326e-a919-4734-8306-5c0ff6ddd6d1    SB016-S010      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  469
4ed21038-cca3-43a4-9e8d-fb9f8bde1b27    SB016-S011      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  470
dfc98096-41dc-4941-ab65-159bf55015ad    SB016-S012      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  471
9a0c4f3e-4562-4079-8836-e57d2cf0c88e    SB016-S013      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  472
0eab60f9-9a11-4d8d-8895-076db4e8b9f7    SB016-S014      Boxes   832851bb-7b7c-4294-9c42-5dd71fff0447    active  473
676c8533-4f10-47ac-b33d-caddf88071ea    SB016-T001      Tacking Room    832851bb-7b7c-4294-9c42-5dd71fff0447    active  474
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customers (id, netsuite_id, fullname, is_inactive) FROM stdin;
e2c4ce13-deb5-4561-bdeb-504e3c5f7266    4039    CUS-01077 Nikki Borg Rutter Giappone    f
ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2942    CUS-00721 Marjorie Harvey       f
fd7cee81-6479-4a50-89b4-89b4d0354383    333     CUS-00048 Rachael Ryder f
c4a090cb-0a94-4f14-b303-fbdd506bf56c    347     CUS-00005 ALI HADDAD    f
8f423989-21f2-46e2-adf5-6c47f716f5af    358     CUS-00022 SHOUQ Y AL NOWAIS     f
d4ea9dd1-7189-4a84-ab87-e0ae0a8dc19a    359     CUS-00023 KHALIFA N AL REMEITHI f
f7fee818-ae88-449d-aecb-619f7f448da9    362     CUS-00028 ALJOOD M AL SAYEGH    f
c516087b-5ad6-4896-a90d-b865713b411d    360     CUS-00024 MOHAMMED A SHEHHI     f
b26abac0-0aa1-438a-9023-fd0e36882de7    369     CUS-00037 ELIZABETH ROBERTSON   f
5f217e94-85d7-47aa-b137-94a3c293c35c    372     CUS-00040 PRIVATE AFFAIRS OFFICE OF HIS HIGHNESS SHEIKH MANSOUR BIN ZAYED AL NAHYAN (Livery)    f
da6262e1-4a7e-4f91-941e-76f3841efc2a    373     CUS-00053 MARAH AL SAIF f
53188f5a-025a-4154-b876-5e4ae1f220ed    1447    CUS-00062 Michelle Schaffers    f
1ab8ff4c-39b4-46e4-8a46-77bdb58f5c88    1442    CUS-00057 CROWN PRINCE COURT / AL REEF ST .     f
56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    1448    CUS-00063 OFFICE OF H.H SHEIKH SAEED BIN HAMDAN AL NAHYAN       f
0e868cbd-6f1f-433d-973d-8d44728a7d58    1476    CUS-00084 Dr Lama Younis        f
1c2d7b81-15a8-4f2f-bafd-f907041a1eb8    1529    CUS-00128 Vickie Kjaer  f
bfc896d6-ea39-4ddf-8d92-0fbb1762ca04    1551    CUS-00144 Lucie Powell  f
4fdefbef-e962-49a6-bf13-038702cc3fec    1559    CUS-00148 Lindi A Alberts       f
4939968f-1b46-4d2b-83ed-7c1a29806579    1582    CUS-00169 Sarah Judith Hudson   f
1d7984cc-9a01-4a0d-ac67-1e53264ce3a2    1953    CUS-00403 Al Shiraa Stables     f
8cd719bb-46a3-463c-be83-24ae1928f357    1770    CUS-00337 ANDREW JAINI  f
d32f4e22-0ceb-4a6a-9d30-3eceb80eeae3    1771    CUS-00338 Mabrook Almenhali     f
1c291ce0-4b3a-4765-a88a-6eddae18455d    1774    CUS-00341 ALI HUSSAIN JASSIM NASSER ALNOWAIS    f
79147b97-e015-447b-a4d9-185987a7962c    2238    CUS-00547 Nastassia / Viachaslau Klats  f
919286ed-0bd5-482e-b7a8-75c925386a41    2115    CUS-00427 May Meyer     f
b98e1c14-1b11-4953-b795-ff41a2042572    4040    CUS-01078 Haras De Marbella SL  f
6025b2e0-6929-47b0-b6de-3e745df20e39    4130    CUS-01131 Louisa Zissman        f
0a04f83a-6dbf-4ec5-bf62-3979f591a96c    3968    CUS-01045 KAR Sport Horses LLC  f
3e04bf98-2062-484c-8832-a6ac763fb9ac    3943    CUS-01027 Mohammad Abu Sheikh   f
05805800-43a9-43e0-837b-16c566ed2767    4037    CUS-01076 Liezel Kadri  f
1e44b508-ea1a-4085-a7d8-91bf6035bfc8    3771    CUS-00896 Claudia Adams f
3defabe9-0ff1-46e6-877e-f78dfabf5c07    3775    CUS-00899 Samantha Williams     f
a6aa0f45-4b7a-4657-9a53-e80c16232d05    3778    CUS-00902 Claire Santelli       f
369d0d0f-5c75-422f-b983-695a04a7f883    3803    CUS-00922 Danielle Threadgold   f
221c65cc-86b4-48f7-8e6a-098b2b894273    3862    CUS-00964 Lisa Vainio   f
b90e3585-1e2c-43a7-8116-3792346ecb73    2720    CUS-00661 AMNA ALHASHIMI        f
3a68c9e2-1088-48d4-b3ff-17231f380ecc    2530    CUS-00607 KRISTINA TURNER       f
e151d01f-d544-41aa-9ace-ffc81e3ce21c    2719    CUS-00660 MAITHA AL FOULATHI    f
e6d95ffc-10c1-499e-b300-17235bcb2aee    2722    CUS-00663 SAM BALLARD   f
69f1447c-0580-44d2-a699-f4dc2ce56ee5    2974    CUS-00738 Hadif Almansoori      f
8ed90e29-86b0-4cfe-a131-c06cb7413956    3174    CUS-00740 Louise Bermingham     f
7f34854a-d81f-40ff-b4ec-b2671dcf95ff    3075    CUS-00744 MARINE BERNADETTE COLLETAZ    f
fe065f3b-9eeb-4682-827f-6f2c25743883    3650    CUS-00813 Ghala Alsheryani      f
af441b86-4b9a-4810-9cdd-7af4f886aef6    4184    CUS-01158 Sumaya Salem Aloraifi f
e8918c53-5c87-4e2d-86f9-91276d63bf0d    370     CUS-00038 Shamma M Al Hameli    f
b065bed6-7425-4e0f-8607-7ccb8b8c61c0    3956    CUS-01035 Al Firas Stud f
3901dd23-92c5-41d6-9b65-b4b356d1d862    4207    CUS-01174 Shamsheer Vayalil     f
6af4bc47-b9fd-4f56-8725-ab513f7eb94f    \N      ADEC    f
0b7d70b1-4e87-4be1-9d49-d61630dd7284    2099    CUS-00414 AS Trading BV f
cf86fecc-4a1a-4ba1-8e60-a9818623ccb2    365     CUS-00033 Al Wathba Stables     f
b6d8a1ce-72af-4a68-b544-0cd212191cc2    346     CUS-00004 NADEEN KHALIFA AL MASKARY     f
909909a9-f7f4-496d-8de3-6e6a5addd566    1544    CUS-00140 Office of H.H. Sheikh Hamdan Bin Zayed Al Nahyan      f
878993b5-015a-491f-8c68-b6e3aec152ed    4291    CUS-01231 Dania Jabril  f
297dd6e6-0736-4735-b670-eb51444f8a21    4292    CUS-01232 Dr. Muhammad Ahmed    f
3fe1302f-fad6-42cd-915e-acef194e13c6    4097    CUS-01108 Shaikha Latifah Ahmed Almaktoum       f
96372285-ae9a-45bb-acbf-95d3447b87bb    366     CUS-00034 YOSH HOSPITALITY LLC  f
c0471f15-cf19-4ac7-87da-2931db694ddd    4122    CUS-01126 Anastasiia Yershova   f
53946bbc-2874-45af-ad7e-6d3d52dc0c25    1549    CUS-00142 Sangeetha Bharat      f
07cc6f8f-59e4-4d50-a1a1-f2e751b9758b    4335    CUS-01247 Rebecca Wright        f
2ac641cb-e76f-47c1-9361-10488823595a    4334    CUS-01246 Elise Monkhouse       f
dbfc0a19-eb4d-4b1e-8c17-0fbc116e8491    4124    CUS-01128 Kelly Acs     f
a19be827-adc1-42db-9b25-fa1a955efc98    4351    CUS-01252 Wadeema Al Raisi      f
\.


--
-- Data for Name: horse_movements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.horse_movements (id, agreement_id, horse_id, stablebox_id, check_in, check_out, created_at) FROM stdin;
500b8c51-2b83-4bad-979f-a076de865cad    e39c91ed-d36a-44e7-8c73-dbf93042ed7c    cc28fa60-c199-4736-8409-5b950cf6b425    67e6b70a-d504-451b-a0b0-fa4072aaaf16    2025-06-30      \N      2026-04-10 13:20:00.873227
65c11ab5-826a-4523-9fc5-5a30cbc48da3    963ccac2-3504-4977-8cb9-b8ae24be4ecb    2328687c-cb15-44cd-adde-141b6d283ccb    214bd414-650f-480a-86a5-622c698b63d6    2025-06-30      \N      2026-04-10 13:24:26.050876
22bfbd7c-96e7-4e85-9d62-8a066a921259    aa520b85-1ffa-4ee8-9615-078a6ff06db0    ae00da66-b9fb-4874-93d6-802223ac2c80    383c1069-03c1-4a20-96ce-e89c59cad905    2026-04-10      \N      2026-04-10 13:39:57.404328
ecbc4bc6-359c-436a-958a-f401d97b3cf4    b75ea39e-a8dc-49ee-8464-522ec2628f3e    97b4bf68-b6e5-4942-8b6e-5f416a726302    2c08a20d-51ff-4b1d-8871-7e2ec0b65568    2026-04-10      \N      2026-04-10 13:51:44.587629
956b750d-0056-4dd9-8066-04f00e5c433f    2ac7c619-d5f7-4503-b675-8605902700fe    ca31a3b6-1260-4142-a1d4-7ffd71b87a80    da0ab2eb-ca08-4958-a03f-7540f884c56b    2026-04-10      \N      2026-04-10 14:02:58.67323
2f542a85-31cc-4731-85d3-2b6be8b02f62    e3e80874-51f0-4279-8602-bd1abb3b5d22    4aa7bb18-d21f-421f-b2c0-8cb7ca16ae90    b0cf9824-3634-4b33-aba1-0990e8cc240f    2026-04-10      \N      2026-04-10 14:11:04.352691
d31a95d7-0a32-451d-8eb8-94df2ac9604b    ec654c68-bad5-4830-902a-1dda90e66dda    ea15f29f-4aa5-43a3-9278-52ed34e73eeb    31a83f9d-a6fb-483e-9a85-2289818b6737    2026-04-10      \N      2026-04-10 14:12:52.783342
4bfab65c-e8c5-41dc-ade1-01b47a6eb015    56886b4c-61c2-4aa8-9f34-765efa27fcdf    0762095a-5f68-4b59-86f2-766cf9ef2c69    d3e34213-0133-4b50-b5ab-70003980350a    2026-01-02      \N      2026-04-10 14:14:39.666169
a725a186-0a54-4426-9a61-5aabea67bab5    f7967797-3262-41b4-a1fd-0ef55091d57f    b5b72cf6-6d71-4831-9699-8f71570787cf    ea18dd2c-50c7-45b6-b36e-df0f5a847518    2025-10-17      \N      2026-04-10 14:17:05.273491
bdb9677c-7d00-4274-9dd9-dbe30fb074f7    a39fbacb-42ae-48da-920f-4e6122c2dd5a    01e81231-bb91-46ef-b8de-4ad8c1c5fe28    ccd96396-4450-4c33-90bd-a32e6a3c2e81    2026-04-10      \N      2026-04-10 14:19:44.79141
4cbb26e7-0c9a-4313-b359-dd0b25533295    efd51bad-03ef-4265-91d4-5a6746f23d93    9e2813cf-e97b-4a4e-80a9-1352ead28d94    eeef71f9-3da4-4028-a349-7688735b2f7e    2026-04-10      \N      2026-04-10 14:23:59.290879
dd79f362-997f-483e-b376-d42e8208e868    eab8ab6e-06ef-4a46-87bb-de9cf0611e79    172f33d7-8431-40fc-84ee-2e35db6094e0    3a3b776f-c4c9-471b-ba2a-136fdb7fd98d    2026-04-10      \N      2026-04-10 14:25:08.080938
943a4389-e944-4bc1-93f7-2c5f3ba3e5a0    8fbea8dd-a8be-42db-9824-36eaa36b598f    cfcf58ce-a85b-4619-b232-b48c2b99b562    715087dc-9a65-42de-b107-5ebcf9f0ffce    2026-04-10      \N      2026-04-10 14:26:03.804792
d99d8183-4438-4764-8402-78ccd65af92f    6a028016-fbde-47c2-a596-73e2aef564f6    579743ae-5195-4dca-9aae-ac0f5e9c999b    71c19df3-c323-4213-a8fa-5b5747689085    2026-04-10      \N      2026-04-10 14:29:07.118031
e069f822-e510-4fb1-a554-cd374f72ba11    a6557202-19a3-4645-83b0-9d63395ee786    7777790e-5fa9-431b-a7db-fab89730eb7f    f93cd1d5-a6c5-4e76-8171-a385f3777783    2025-12-28      \N      2026-04-10 14:30:47.853764
d522096a-cb70-4435-b55e-950868f64ac6    ed3408de-2e7e-47ce-95fc-f6f65df2456b    36e4db8d-0529-4432-8872-6b34980cd0b4    ea3d6601-2949-4533-9e49-55c585e7d5f1    2026-04-10      \N      2026-04-10 14:37:40.362554
395c50d5-3c38-4b98-bfe9-aa98ada3cbef    4c73c706-6945-4110-8f8c-c146a54bd964    7fbdf19a-ea91-4a99-a23b-03a7727dd6d8    286ddcad-9db6-4b76-9e14-b96bb403493a    2026-04-10      \N      2026-04-10 14:38:43.160743
975a4a28-8caf-4da8-b944-a0679254d5b1    5acca11a-b92a-4177-86af-ae9f9aaf9915    3388f460-d815-48fc-a427-1289adc0ea2f    c6e77b87-6119-4743-81a3-c10f648599dc    2026-04-10      \N      2026-04-10 14:39:46.115702
7017f763-4943-4824-b92d-c19ee079c6bf    af10d581-1db5-4b16-bac8-e1b28c6ec705    19055267-8534-43b8-88ee-a303a114c8de    3cead808-232f-4d8a-926f-f3c84c731211    2026-04-10      \N      2026-04-10 14:40:55.22718
48424400-bf3e-40a1-a0ca-f1bc2561ab77    9f97e0fe-86ab-4a73-99f2-f16d7e7a34e9    77c11e6d-5270-48e0-a0fc-75e34e6a8e95    3bae3844-10d8-4140-b2fb-468b35bd5640    2026-04-10      \N      2026-04-10 14:42:37.113373
56193e82-0005-406d-a557-2011264b2feb    2bcd2cdb-3340-4a88-80a5-25973253933b    469b0c8b-03d9-47a1-aca6-57d0da2ff468    cf2395f2-80d5-46cc-b770-45a05f0f8583    2026-04-10      \N      2026-04-10 14:44:07.11087
3c56adb0-c6a0-404d-a703-4d8367395ac8    a78ae6cb-eca2-4902-ad6b-dbdeb506d4e9    3193395a-d8a5-453c-ab8f-3674d4c5b4b8    596ce3b8-9c3b-410c-9385-87d1388e78dc    2026-04-10      \N      2026-04-10 14:47:27.490429
948df22a-37da-423a-9198-da6a81d34378    470b1df7-928d-4c53-bded-d00cc7db60fe    d1bd0d41-d836-4819-a121-067d370a6365    c2210c19-cee9-4e94-8126-03a399249ebf    2026-04-10      \N      2026-04-10 14:51:17.739515
1ce2e380-47eb-4b9c-a255-cf9e43f13eb1    10dcb153-7fea-4383-ab58-f1c112af5a70    94b162e6-a9ac-45ae-8411-7c430256474b    afa6afc6-3dcb-4dc4-bf5f-290ed1ef44c8    2026-04-12      \N      2026-04-12 07:37:02.145001
8d76eb70-05f2-4d3c-9c3e-e007d056792a    e29364a3-3422-4849-9b8a-9bc621cd7a37    ab89b82b-0bbb-4ae4-91c5-c942f5e53bbc    ea0ac33a-7727-4835-8b19-143a7e6bd56c    2026-04-12      \N      2026-04-12 07:38:46.220942
c754acd0-acac-41c9-8674-ee04f4d9f161    828f4d13-1d9c-4155-8bd0-fb2178999f79    b888a087-a089-44d8-ad06-4cf1f2215337    53662acc-b1ed-4158-887e-5234d928404b    2026-04-12      \N      2026-04-12 07:41:57.579964
909e3902-fcea-4d28-b1d4-79dd8500de52    a301d561-15ea-4ee8-97b3-7d574e7938a8    572fe76d-fddd-4422-ac7d-328182d752af    b4d357fd-5b04-4378-b379-9f1632d96143    2026-04-12      \N      2026-04-12 07:42:11.662535
db4a9cb9-424f-4b47-b093-480048390e88    dde5166e-43e3-48b8-ac0d-8b5d43f04031    52f2e259-349c-4055-b3de-6bdc4b107345    c913f90f-2b84-45de-86fd-2d0ea336bb3d    2024-10-01      \N      2026-04-12 07:43:28.046358
d728ea87-0ba8-4590-b086-4f0a409252bb    2c9cff1d-7b6b-4a53-9dc0-081b2446df3f    05094d8f-70e5-4baf-bf3d-f152d0cb0193    08dfae91-b9cd-452b-b102-2baa08b36165    2025-06-24      \N      2026-04-12 07:45:05.067787
f7e06cea-08ea-4361-a2d6-d5d61ca2cc12    047c8299-8c3c-4f81-9b3b-3946c6f72c6b    0a87d9f1-9a42-42e7-8062-52f03d34db3e    c0d83349-f24a-4c0e-b08c-b9a8d4eca067    2024-10-01      \N      2026-04-12 07:49:00.484137
2906bc98-78c6-4e23-899f-c69a3ab66d3c    11dcfe17-4df5-4c59-863a-f3b8fe6158af    277654c6-5920-4d72-904b-0bac576bb7c1    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    2024-10-01      \N      2026-04-12 07:51:26.937439
89a5e3e7-7e7e-4754-b326-47db607a49d3    dd81c6d0-b66d-4ce9-82e9-d6e9ad835354    b01f993d-3701-4f15-a873-a7c3b8662689    2eb22dd0-9df6-44af-8174-3e35ac405704    2025-03-29      \N      2026-04-12 12:33:58.353213
a026b087-c4dd-429a-a926-0b67bc7fdb15    e74a728c-e594-46fa-a686-c08b87fd9f9e    d5bd7ece-ce0c-4ed9-accb-41b61a45f9fe    5da98fb2-8983-4ea1-a7cb-ca84578a2b47    2025-11-15      \N      2026-04-12 12:39:16.841947
197c1e90-8aed-4bb0-bba8-bb05d678ea1d    eb1f2054-37c1-4c9a-8b27-7421ae3dd6cb    fd18ceff-2c9c-4a44-bfd0-a060d249d617    7282059a-1968-4468-9ed3-b20526f10ee7    2024-11-15      \N      2026-04-12 12:40:16.460383
7384782a-aebe-4cc9-b6d5-4c03b2d706e5    85247fa6-758f-4ceb-a245-83f03be36b85    6ebda625-0073-4929-8dc6-be1f11b77dcb    8608c09e-7c7b-4298-a828-aa5e54a9aa9a    2026-04-12      \N      2026-04-12 12:43:07.553675
359c959d-147d-4b57-8aa3-f36861647d08    6252dd06-7948-44c3-8b76-8e1e01b62622    b3b2064b-9d98-4f00-b9b5-92d551ccc0c4    d1e0d953-04b6-4787-9de3-ed0379f4b00f    2025-02-04      \N      2026-04-12 12:45:46.422522
d57b1d19-622f-4bf1-8214-612d448f2fb3    1a8dc5f7-44c2-4c71-b573-0289a6792c3f    44cd7916-a904-4878-a7ed-204b372246aa    fe89df4f-307e-4a15-9080-56e50739987d    2026-02-01      \N      2026-04-12 12:47:21.120733
a22dfbe6-f4a9-4c99-8ad4-9f4d5807f5ef    4b976b15-0ba5-487b-bbb6-6b83753c2e0a    7a443e5b-439e-406d-9071-7cb8bad8f55d    07f4f82d-42f5-46b0-b293-ecfc732178c8    2025-08-25      \N      2026-04-12 12:48:23.595652
5344734b-78f8-427e-92f4-2a0eac1e1ad4    c248c9d9-2483-44e1-9480-3a26da27f876    9db24d66-dd17-4bc7-b792-28ce08cd0462    6b3a2f08-412d-4c8e-8716-214e91fa8dad    2025-02-02      \N      2026-04-12 12:49:55.647216
709eed78-b4db-4924-845c-90ead5df0203    e2d47b81-6601-4db4-bea4-364757be60c7    e0835fce-47bd-4f05-8742-539a39282951    f719dd6b-4a6e-4344-9018-02d2ca8267f0    2026-04-12      \N      2026-04-12 12:51:00.342514
c318319e-9e10-4196-8544-e5eeac65cf09    f23d4cb8-8ec7-4549-8f86-d7547d5e176f    b612fd91-53b2-48ce-bc9b-d3f8203c60e0    2732f6f6-5e0b-4231-8a5f-d9baaeb411e3    2025-12-28      \N      2026-04-12 12:57:58.478233
252b4ee0-f78c-4dd3-aa40-3037e961a6df    84dcd7f8-dbf2-43af-992d-970c2a8ba64b    2416c8c8-cd59-471f-a486-907f2f6e6fd3    fc59e00d-7f34-4dbf-9e22-f5d201ca748f    2025-09-20      \N      2026-04-12 12:59:29.773097
4b518ba4-eb93-4550-865e-e659c7461f7a    73fe9898-b3a5-4a88-b687-a3bf947be318    c04bd1f3-aeff-4914-be91-46d11076568c    490f009a-d7b4-421b-8c9b-a052ead040a9    2026-04-12      \N      2026-04-12 13:01:41.150834
9667be53-4a8a-431e-966a-7c97e52af2d7    205233e9-491a-4038-b395-6814c7b98c07    1ff9dd76-62ea-464c-8e5b-d0ef554af4f6    9d7e3d1f-744f-4326-a236-1d1f0dc4ab15    2024-10-01      \N      2026-04-12 13:02:50.659079
8d1d9e87-542a-4330-afeb-b403c5eca2c2    e143a973-3a8c-4626-85ae-8f55f36b75b1    ab2fc725-da06-46e6-8b5c-6f900d7c4e8a    381e7902-95aa-460c-ac0c-2fa03883c20e    2025-09-25      \N      2026-04-12 13:04:31.459996
cccbdf23-5b79-4dc2-aea4-4ed11d1fbcfb    6d788b08-240a-4106-8d27-98cfb0ba4640    2a567155-2e2c-4153-9257-4b971c12113c    9d0d7f8d-28e6-408a-a53b-35d285debb35    2025-09-08      \N      2026-04-12 13:06:36.265612
56c4c6e3-5c41-4347-bfc2-730837d22442    c5493602-a71f-4766-a45d-c2d33bdfcdf0    34e07531-488e-4e26-bf46-b156f5c92376    b90bead8-11d0-4782-8147-537cd223d21d    2026-04-12      \N      2026-04-12 13:07:41.908458
1aa4f866-bafb-4398-9d06-3a527c639e24    44ea6aca-3b79-4b70-b050-2c11e929a942    8d77b2ca-3a06-4397-b4f1-82940b0cd471    e26c7447-d6a7-4f97-9fed-863110a73d89    2025-05-14      \N      2026-04-12 13:09:02.65179
9812bf5b-6b30-471c-b09f-f30bfa3f86fd    2c051d7f-c850-4255-9048-f017293c0a97    265dc87b-8136-4af8-bf84-15cce35a2a08    29658560-917c-4df5-8606-bf053689b49a    2025-03-11      \N      2026-04-12 13:10:37.300587
158ef0df-cf7e-405c-aa7c-e2a30f70a478    eab9ed85-8908-44b6-97c4-9c087807aa27    370ada88-9266-4154-ae13-35e8726bc871    efd99a5d-7cb1-4fe8-a119-83f8b792cb0f    2025-03-30      \N      2026-04-12 13:12:36.401164
d0258fca-a90c-4cf3-8169-60acf6a95229    94663740-d04f-443a-8309-17780d884077    dd16f58a-048d-4e3c-9d49-8e5fe253136a    b1c71e70-c705-4779-bff3-d8ab0bf231f4    2026-04-12      \N      2026-04-12 13:13:45.448004
1e8bb8e5-97ce-4aaa-a8cc-9aae6080e7c4    e94133b4-ba36-4078-ab67-9e3c1ce0e3c7    3ebae8af-8b4c-41f4-8dd7-865708466f62    6a8b068d-9544-4486-b976-3b360a04e42f    2025-04-08      \N      2026-04-12 13:15:26.758964
15c39f70-8251-485c-bb4b-ad138f1e5a59    3ecae716-2aa4-4f29-bd63-759f080bb711    8b29306d-783b-41ea-b521-7e671b855687    dd80eaa8-0d46-4c1c-94bc-84b3103406f2    2025-08-30      \N      2026-04-12 13:16:53.341855
ed2b98b0-8e00-47ad-a122-8c9449f00fe0    a621e7fd-ea3c-4b02-836b-2146fff023ed    8163b10e-1308-442b-ad73-43dac0f0206b    fd088d87-96f7-442c-8fe3-9e7175b506be    2024-10-01      \N      2026-04-12 13:17:44.671182
090561ef-c791-4fcb-a7e2-79438862e5a9    f80fb283-a9bd-4032-b94d-2cc7604552fb    04edebe1-cf3c-4e57-8d06-74fbfc443930    9ead1266-5a16-440f-9816-965061849531    2026-04-12      \N      2026-04-12 13:18:40.176285
663fc06a-349b-450a-b579-ebfc01136bb1    bef56d65-f228-497a-af24-0bbfac64703b    28f3fbba-d41a-4c88-ad2e-09983513545e    26379f79-ec39-45f2-97f8-b60de93f0e25    2026-04-12      \N      2026-04-12 13:20:35.822415
c94db5d7-f69f-411c-be4c-a5c1713bb61b    9b1d42b7-9ac4-4d7b-aa6a-e5a9e3421dc9    b22b322c-6035-4697-9309-c8a279786522    c38baf65-24a8-48a8-b5d9-0b51962718c5    2026-04-12      \N      2026-04-12 13:28:45.269134
e3680e40-0e4b-4d81-94f5-99a39cf810a5    55cdf57d-db44-436d-a52f-2ea5948ad0f1    683d28c5-09ce-4886-adaf-c2378c3ad86b    5b1b3a5a-6f46-4bf6-8ffb-eb7b887c0153    2026-04-12      \N      2026-04-12 13:29:44.829176
bfb28ffc-c9bc-4c98-831b-0970cfca170e    5da92382-674f-4dca-8d50-ecd03859ab13    9f2b32d6-ea20-4dcd-be1c-08e33d516b43    bfdaa14a-0158-4eae-9acf-7f58d4b99863    2026-04-12      \N      2026-04-12 13:31:32.791202
c78f84f6-0322-46a9-8835-26071f09451f    d0ff2a0f-c59b-4bfd-9f75-b28ca81b75bf    666f76e1-0fe1-44ca-86e5-d2d79f2058aa    ea9b80fb-7a90-4223-b33b-7b79bf0256a5    2025-05-14      \N      2026-04-12 13:32:52.511952
e0ed983c-bf44-46b6-8fc4-3af89d378134    d46e6d55-a2ea-4c35-b75b-5d1d88bbdbb3    d1a9475d-30f2-4565-b9cc-cb47486d4370    c2e10b2e-d645-4752-9bf5-a704453047ef    2025-05-14      \N      2026-04-12 13:38:02.753261
05aec940-921a-42d5-ace6-af02aaaa5257    bc66e8b5-2972-4793-bf92-e3e45412faff    5d67e9af-fe4a-4666-94a3-674f6506745e    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    2026-04-10      2026-04-01      2026-04-10 14:05:11.891646
2d1a3899-0b5d-4de9-8e9e-f15ef618cd33    17b270a3-9b9d-4336-a47d-41a3e0827675    5d79a957-f397-4a34-a645-03c5334fceb3    7842c10d-d9af-4a31-bcb1-c3991a8644ba    2024-10-31      2026-04-23      2026-04-10 14:27:20.270637
ffbfb1f0-7b81-4c88-bbf3-952b5fe112da    bd4d6227-5901-4ed9-8f36-54c3c149c7ae    7e7bd2a3-b4c7-4d0f-a476-f05d74f5825b    cb6a2ab2-ee83-4b90-a3d2-c8a6ac6a55fa    2026-04-12      2026-04-27      2026-04-12 07:34:33.949123
a1051a6b-ebc0-458f-bd06-13b81e2cf2af    72fba684-3a74-4a4a-9b6c-c21f69482130    954d068a-4eef-4a26-89c6-46c7eaebd19f    306983c9-0076-404d-885b-42f1801cfa88    2026-04-10      2026-04-29      2026-04-10 14:21:36.879386
d1ccebf6-8c2e-4782-ab3d-a60c9043a814    bee8af2a-5fc0-4624-a5ab-7b9eb45f8cfa    c3cf1475-cef0-4166-bf49-601a888453cc    7a08de89-a9f5-4dd5-8b1a-6ce585b57e76    2026-04-10      2026-04-30      2026-04-10 13:28:41.548806
4295f75c-62cb-4792-91e1-d415dd2fbabd    0bef9c96-2792-441d-80a2-6b292d33210a    98578b91-c647-4d6b-baba-9bd4f6aa591a    0ee5fcb6-2aa6-426a-9cf8-ce41f46d4d23    2026-04-10      2026-05-06      2026-04-10 14:01:08.148383
3d670924-5a94-43ad-9e06-31335b51ac5a    c16b9e28-f638-4839-ab11-6d1d257e73f9    715001a4-6f81-4557-b7b4-4603c367c922    c305222c-ef2c-4cac-a860-53617169f789    2026-04-10      2026-05-06      2026-04-10 13:56:33.44125
e45cb29e-1f73-4750-8e42-8a3acf619047    91343df2-d3fe-4165-a5e4-0729f87b6324    e73a0e9a-1518-435b-92f4-81c6d1a2570e    b599127a-3545-4e8c-9a02-c6e0a8a9a021    2026-04-12      \N      2026-04-12 13:40:48.827978
6ad99a24-3ad2-49e7-9f4e-e22a1a1a0894    8247d7cc-052e-4622-86d5-d24c23a24c0c    e38c9510-b163-4946-9c70-cbc41e33d2cc    f3ea3726-2d36-4112-8a3f-a14973c47106    2025-05-14      \N      2026-04-12 13:45:14.585402
6aa357a7-8a63-4122-9c6f-b3a05f926c87    67f16924-16a3-45ef-95db-b50e501666df    2a12df79-2327-4240-8140-63b6eeb3b1c8    ca2da968-1d13-40a6-9ce9-80a3451cc0b5    2026-04-12      \N      2026-04-12 13:46:01.88405
443b1e5b-7813-4637-8ae3-b9e34a3195d8    e06ccadb-ed0a-4c88-acdf-5d2d5691ef6b    ba17ad82-0b0f-4b7c-ab76-ef1a1eb41901    14bd38b2-cc6d-45cd-a8ec-7e619ae363c9    2025-05-14      \N      2026-04-12 13:47:41.239745
610373f2-690a-417c-89d5-411d82515167    971f6b22-4336-41e8-80d4-f38943f36f2c    e67173c3-b0a7-47c9-a703-b82fe0d6d0d6    88db7ecb-cfb3-407b-b149-0dd7de29f641    2026-04-12      \N      2026-04-12 13:48:57.055156
a26cccc0-6902-427f-83ad-677d9558778d    ed861515-3b31-491a-96b4-49e913e32add    5b8b8905-f9b8-4331-9e78-b670baa9e790    85489880-a902-46e7-b9ce-47a7b87c0e55    2025-05-14      \N      2026-04-12 13:51:08.329029
afc4dd88-9e60-4642-b899-c97c29857877    577d1b72-adb1-4bb2-bfa8-52b4568bbfab    2ff25291-c7b6-4e4b-91c2-d4244b1123fb    715646b2-6870-49eb-a9f4-fc55f21db630    2026-04-12      \N      2026-04-12 15:02:01.424032
380fb9c7-99a2-4125-beb0-21a8c2eaa41c    da821b07-eda4-4b44-a037-b4492435ab51    6aaf4500-ea31-4dd6-beda-63f91e2c1712    1d3b9632-116a-4cd9-9a0f-6af24740d36d    2026-04-12      \N      2026-04-12 15:03:32.032393
025196ad-a9cd-481b-bfeb-756f0ea99cf4    41742b12-84bb-4cb5-be32-9d2d6cc319f5    c23f295d-2bee-4c15-9c2f-0ca3e1d9143e    e14cb4f7-02d5-4417-adb0-78cb5caa71f1    2026-04-12      \N      2026-04-12 15:04:35.003257
116d6d46-5d86-436b-92ce-054037f310ce    c5d40c6c-a163-4725-9d28-ea3912782fd6    08568f63-6a52-4dc7-9553-8882ea1729ee    3be807e9-0a9c-419a-8710-f323e5d82ba1    2025-05-14      \N      2026-04-12 15:06:28.958339
4c8ae1e8-90fc-405e-b615-7411796967f4    fd6ca2a2-edd8-4717-999e-00d94d14092e    1cfae32a-2431-4b86-8e1d-0aa13b0b7578    9e6d419d-be37-4418-92cc-33b2e3db17dd    2026-04-12      \N      2026-04-12 15:07:35.441417
bb87a5e0-9c56-4c91-a7cd-028e5338f0a4    1696abad-761a-4397-a148-408e36a6c286    05bf209f-ac57-4075-b11c-b31cb8da1503    b10d2896-646e-498e-af78-c8b13b1c5fd3    2025-05-14      \N      2026-04-12 15:09:23.846984
82fcc12a-e7e6-478a-97cc-8a3e7418419b    bdcadd5f-3168-4767-ad61-8cf94dcf97a2    c16c4cbd-3c0e-4129-97e2-a14cccb86bd0    b60db2ad-d999-456d-b56d-b0e210f0c250    2026-04-12      \N      2026-04-12 15:10:23.692067
f18e2ca7-1f35-4014-a306-f48ca5abad62    cb3ef667-f440-4d62-bead-3ef77e6e74ae    8df73a20-0b00-4222-8a62-53ce516a7201    db44b2dc-291f-4053-b285-daf9342bdb16    2025-05-14      \N      2026-04-12 15:11:33.39783
af5a6c84-84d1-4e9d-8d46-4886af17dc57    e20e6baf-10b6-403b-8695-189898e5d124    b77ae74e-6068-48a4-ab38-4a321d6ee2a2    26ea949a-8ce1-4ddf-9e0b-4bd6567aab2f    2026-04-12      \N      2026-04-12 15:12:25.112398
e51f3e71-62a2-483f-b9dd-c2ee6c05f777    3bd58602-8159-4f6a-b65e-4119e546db1d    f378c4d0-9cd6-4507-a22e-3327f67cb27d    6f0b6748-5c51-4100-9b64-66058ab10ebb    2026-04-12      \N      2026-04-12 15:13:38.217178
d79f321b-d70a-4688-845a-e5c6e1be3cb8    be843786-6f31-4e06-a062-afb82ad39291    0e711139-3a00-4a45-b7fb-53b8c53679ba    6de10c03-eee8-431d-9886-c5dc5b98efef    2025-05-14      \N      2026-04-12 15:15:00.347524
3910bd64-8934-4bcc-9871-407d77b73f59    13562d64-eb5d-4764-bbad-bf3afa332fc9    d4b37e9c-0081-454f-a718-af4cdb007f81    bdfc656c-12c5-4858-8ba1-c7b108b17e2e    2026-04-12      \N      2026-04-12 15:16:10.884723
f6c0a158-8b6d-4e95-8556-b76b3b641186    4ff9ff90-c128-4e3d-a982-3b5f34657acf    26b53768-699e-4fe0-bb45-e0cea76461d4    74bb3a04-592e-4f25-a9ec-0511d1e2a8ee    2026-04-12      \N      2026-04-12 15:17:25.017092
3ddb17e3-93af-41c8-96f0-872cae98199b    efea762f-d6d7-422b-91a1-01e4e94feb4a    694a552b-db84-4e21-88d2-218c6de7fb4f    ffa87a9b-1596-4f69-99d5-5b8cc6b01487    2025-05-14      \N      2026-04-12 15:18:47.59773
3fda191f-63ac-492b-ac6d-c725b87f869b    62fdb2a4-1bf5-495b-85f0-f442d530e98f    5c489303-0640-4eab-a8cb-dffdf2200f7a    b129d22c-4c07-4090-830b-9ccd8cea6cd2    2026-04-12      \N      2026-04-12 15:19:30.172818
04ecf5a3-3500-49e2-b821-e2cbf8f16c4d    ee062a5e-08e2-4503-bc70-434f80165f8c    1f9ba834-2060-4c64-b3c4-e85d2d90c8af    ded1129f-2091-4e7e-b655-e86ba6501e45    2026-04-12      \N      2026-04-12 15:20:13.992978
8ee83694-ea7f-48a7-91f7-d04857ae808a    31fadc25-ff42-45ce-9178-a2cb454128bd    d4f83442-a140-4edb-9ae0-fd48a9785d91    13009090-2ea8-4cd6-a070-6f86e789ddc0    2026-04-12      \N      2026-04-12 15:21:04.296163
cf9e5dc9-35f0-4b24-b90a-54899ce58e94    34331cf6-b646-46b1-964a-9e4a2c159b72    707d8ed3-9b2d-4e0c-b5bd-4f03174f49ad    a80814fa-d452-4428-a3da-7fdf5163b0f1    2026-04-12      \N      2026-04-12 15:21:57.914016
709dd022-14e2-4e5a-b337-673a519c8402    c3602a8b-aa66-4339-aa18-a346bdf3e6e5    ebd1fc51-94d5-4dab-b25a-34e7acf799e1    de282b0d-5fbe-4ea2-b402-814d1f9b1a39    2026-04-12      \N      2026-04-12 15:24:05.863255
a6c7d5b5-ab9e-4dd7-8166-dadb689350ca    bb6d2c20-bce0-4f5a-9c52-2ae89f629072    512ab1bc-a848-429a-9087-17d7078681a0    b92a389e-84ce-4698-a547-506d0b6eb7d5    2026-04-12      \N      2026-04-12 15:25:14.835809
08476c47-f969-4cb4-a1a9-49d91a6a3341    bfe80498-2b3f-43bb-9cee-2ca25e65c755    60ac0380-e9e3-44d7-b358-1886264a2b00    890410e0-e08b-4b50-acf1-722e3689f566    2025-05-14      \N      2026-04-12 15:26:24.144879
7a208a05-1e1a-449f-bc6c-415491be7273    7a38b68d-9dfd-4ebd-ad20-c09127aaab0a    971b1adc-396e-44ca-99ef-0fd467f9ac76    da79a244-bc94-4497-8c03-4fd84f028b6b    2026-04-12      \N      2026-04-12 15:27:51.866718
7d7d0e30-7c8c-4ce0-a0f2-26432945f60d    492838e1-af27-4170-9f04-44c414a6ac8b    9dc9c619-b7c4-4395-9920-9bebe2adf29d    eb6035c9-e416-4d1d-a76b-96ca68ea5e2d    2026-04-13      \N      2026-04-13 05:52:47.271918
62e5a108-f503-4f85-bd43-b76acd86a301    023bb5e6-d199-47f5-98ac-e56852e328eb    b21d3c3e-0f48-4d89-ae09-3479eab4ade8    513e6d4a-7dd8-4430-8b5a-f60f305da19f    2026-04-13      \N      2026-04-13 05:54:05.547207
7aff8b4a-a682-4ce0-8cc6-ac34022dcc07    40512c80-33d1-4387-92cf-5e2de183cd83    11d1ecad-f343-4fce-aaf3-60fa983f9b79    bea81e77-b3b2-4f51-bccc-a205b0ef1d3b    2026-04-13      \N      2026-04-13 05:59:20.904348
d1d9c73e-7435-4b4a-a5df-f71f33e6f455    cbc5ff28-d107-4579-b6ae-9821d98d9953    b0ec4749-710c-48fb-9016-6db48202040f    cd23bd11-d682-4018-8d8d-469929891b2a    2025-05-14      \N      2026-04-13 06:01:03.081981
d83d3be2-0aa4-4044-9120-cbe0d73f697c    100098a1-7623-45d0-98bb-9cc27df24f97    a910888e-eb39-491e-95e4-5a1a338efe4f    ffac5902-fe2f-435d-8487-fd9dee136dda    2026-04-13      \N      2026-04-13 06:02:26.799333
55f52b1d-031d-4bc2-a1c5-6b39622d5e2f    4c591c4e-0bb5-4883-9efc-fd68ac6d86c8    bc785f1a-5963-4c21-9d34-b7fbc01674b1    f187473e-04a7-4e38-ab67-1a9089b27270    2026-04-13      \N      2026-04-13 06:06:28.830839
7e846abf-5123-4f8d-b3db-8ee64c6895ba    3a43dba1-7064-404a-885b-235a91e3e3ad    88f847b6-caaa-4736-bee8-13ff4caf88b7    65297e5e-6f0c-4679-bc90-f77205b88e9f    2025-05-14      \N      2026-04-13 06:10:19.012127
c16effca-f6da-47d7-b5d5-8558593731fd    118851e3-bb70-40b4-baef-e0b166aaeb33    1abc3ea0-a055-45d2-9fd9-ff3da182e5f5    940ce4e7-bde8-4180-bfd5-4616b6cc9679    2026-04-13      \N      2026-04-13 06:11:10.513118
45651acc-3062-440f-aace-b1039a3f658e    aa2debbf-65cc-401c-a893-7118db8776dd    57e9d488-fa06-49ff-a829-565080196562    cc285778-b716-4c19-9fd1-b938b97ace63    2026-04-13      \N      2026-04-13 06:12:06.638389
011496ca-c6bf-4723-b31e-674bec316f6c    22611492-a4e5-4508-ab53-73603061e29b    275c4ae5-fd82-412d-a07d-334e94f6a46d    1d1bee69-3040-4551-83fc-2e0824779e61    2025-05-14      \N      2026-04-13 06:13:24.542429
3511eb25-771b-4561-926c-743fe2acb44a    b547cd06-f025-41ff-ac1f-c737fa25b992    f73bc29c-b715-4968-b437-51302ec39fab    3406ef48-3fa5-489a-b422-115cd514bdf1    2026-04-13      \N      2026-04-13 06:14:36.771738
ddb10e1a-a2fb-492d-ade9-e0f9b1b33768    01023848-27f2-4fa9-9353-898ff9671bb0    9c27b6eb-248b-4d56-a688-ec67330a0ad6    a9f49b28-fd08-4c9f-8455-300e6d86963d    2026-04-13      \N      2026-04-13 06:15:25.7429
382eb7ca-8b67-49bb-8c30-135a25aa4b2a    953f8e4e-0fdd-4c25-b5d5-1675d60f68c4    323c54ba-b227-4807-b018-5c47f05caed7    46aa0262-f8e5-4595-b558-7ab4c1abdf61    2026-04-13      \N      2026-04-13 06:16:57.268568
3682888e-2d3e-4f54-81a7-394e1ff23d12    ccd73b21-f66a-45a9-a7df-485375938b68    98e66e07-9adb-46c1-86ee-0bd6d16b8f41    d2ca6e4d-e86a-45d0-9ef0-70e63f0fe65c    2025-05-14      \N      2026-04-13 06:18:05.650209
7b178b6b-16c5-434a-853a-297021a4b508    b63523f0-981b-4213-9cf8-36b308363c6b    49800c23-738d-4282-8a44-d1a4ccf11e63    bbeef4fc-b1e6-4977-98c5-420d84869653    2026-04-13      \N      2026-04-13 06:18:52.06095
925fd943-1821-408c-8267-4c53fbc5ce94    24b5874e-1fe7-40a3-9654-3885b72045c6    8a8720a8-a9de-4f04-875f-449ed3af9556    1f222285-3e81-44ed-8cee-2e31e1e47a97    2026-04-13      \N      2026-04-13 06:19:49.576066
ffbd4e80-d2b5-45ae-835f-50b1e975b31e    ed0c7101-2f4b-4594-8e09-b70868861062    fc513ffa-ebf2-4e26-b9ab-c0449ac1dccc    08c28d47-9061-40ad-9dd6-b8a97c2e885a    2026-04-13      \N      2026-04-13 06:20:46.641808
aaf10346-7720-4b1b-9bbe-92297afd46f2    769d85ae-f864-439a-a401-3ee6f272353c    e194f17a-8924-4f6a-8a05-96a152a43a74    706522da-797c-49d3-918c-891db403993c    2025-05-14      \N      2026-04-13 06:21:53.745344
b22a63a8-8f9c-4a4a-a2e0-16c3a4066ef0    37a6eabf-8f3b-4993-9797-563a9f1b0565    b189c9c9-5544-489e-a977-0efb23c28182    2a5d586a-b056-44cf-8cd1-a35b634adcdd    2026-04-01      \N      2026-04-13 11:20:01.856051
8395a24d-4f62-4c6b-80a9-52dca00ab85a    f92e40f0-3188-4b4b-aac7-2a9386ca9814    31c8d10a-4c86-4312-b87f-789bb093ae64    a6b06986-d142-4366-90dc-64f5ab23ab78    2026-04-13      \N      2026-04-13 11:20:29.123674
4333c63d-3463-461a-bb58-86565734ca11    4291bb46-d0c8-4e02-b3bf-4e8e8fd688c1    d3ccaeaa-0818-4e87-86b3-3f4602fc27cc    201edc18-e979-4795-9396-e11f7a579347    2026-04-13      2026-04-13      2026-04-13 11:22:20.553014
9a63d308-0023-4fe3-8bd5-fc05870a028b    36e479ca-f1d5-41d1-be08-f0d995046e98    e49738e9-8f0a-4226-90ee-161f2896cc6a    27d39b5b-c47c-44a4-903e-5a01f8e181e9    2026-04-12      2026-04-01      2026-04-12 07:47:24.285398
b66d3877-0b89-46d9-ba24-bf5818978a12    9b025149-2c56-4dbd-80ea-2c2849edb1f9    c7015dfc-588b-42ec-9da4-3b57d5ef5c76    f3b85547-5092-4f72-bf25-b65a010c58fd    2026-04-15      \N      2026-04-15 18:34:44.56206
fd08775b-8b4c-4b61-bf2d-65c82b277fc9    e8e4adb3-7be3-435d-8d94-15c157586e38    d3ccaeaa-0818-4e87-86b3-3f4602fc27cc    f231df6c-a72f-433a-b5ca-a88981152eee    2026-04-01      \N      2026-04-28 06:33:48.94583
9219a68b-6909-4740-bd5f-9209e55f0c30    275d4902-18fc-408f-ba3b-1919ee02cb4c    cf937986-711a-402c-87e1-66c76e50576d    3c790387-76fc-4fd1-893d-884498cbd8da    2026-04-01      \N      2026-04-28 06:34:06.048949
abc4a931-0ee4-4c6a-bed4-8774f7ea3377    78f872d8-f649-42a0-9bfa-e2170cfeabab    699ff103-7bd0-4866-a818-2a0b3d3ed141    1a74eb4c-4815-4721-824d-4d0443fe307e    2026-04-01      \N      2026-04-28 06:34:21.720144
327b95ed-4b35-406c-a6c9-fda206f821af    4f952c41-1621-4e7c-a528-e9ebef8515c4    68c49dc9-9880-4115-99a6-c8dbd28b760d    5fb2de9e-1363-42ac-93e7-8504fb0062fd    2026-04-01      \N      2026-04-28 06:34:39.039674
1780a499-0e67-47fc-a021-268d6f1e0b6f    976428ba-6eaa-483c-b01d-1d0fb91f0955    217838db-92a3-4f51-b25a-ee20901329ec    2d9bf537-4771-4e91-ad5f-c67e9178d69c    2026-04-01      \N      2026-04-28 06:34:55.88473
bb82ae09-0d22-4a0e-b455-be41c3c531cf    8c90c419-24bd-4104-b2a2-72761f446676    169eafb1-86f1-40d5-8fae-095a64208fed    06405660-ee33-4a64-a126-b6e072ee6e7c    2026-04-01      \N      2026-04-28 06:35:12.136505
a87d888e-1a3e-4264-90cd-f5ac2bf48b0a    c697f17b-cdef-47e5-b0cb-9cd9ed1a3ba0    1c9d36f7-0f9e-48ad-b6ad-471002e4f78d    728c2e50-8cfb-4748-bc40-b5e9964c4d1e    2026-04-01      \N      2026-04-28 06:35:26.316331
7f2206f7-561b-4226-ac7d-e7c556e2b2e1    bd4d6227-5901-4ed9-8f36-54c3c149c7ae    7e7bd2a3-b4c7-4d0f-a476-f05d74f5825b    cb6a2ab2-ee83-4b90-a3d2-c8a6ac6a55fa    2026-04-01      2026-04-27      2026-04-28 11:40:51.391553
67d6afeb-0abe-42ba-85f5-a42f7afefbbc    17b270a3-9b9d-4336-a47d-41a3e0827675    5d79a957-f397-4a34-a645-03c5334fceb3    7842c10d-d9af-4a31-bcb1-c3991a8644ba    2026-04-28      2026-04-23      2026-04-28 11:42:26.58069
90c7051a-17ce-4c8f-b195-089ac7b38684    ea0db11a-b11e-4702-9c7c-3016963760ae    50961ee6-cf34-40ee-8bdb-d37f55069ab6    a646641d-afe4-45c1-a126-1190cfc13fc1    2026-04-30      \N      2026-04-30 06:43:55.892447
6f1329fb-fcd2-44e0-bba7-2ca99d71f92b    de7d1200-1908-4458-a02c-1e8d437ea3c5    ae794684-5b89-45df-8879-23139afc992c    e6ca296b-f4e3-4a24-81ed-53b87916b1cc    2026-04-30      \N      2026-04-30 06:44:42.671864
31c1b94d-f9ae-44e8-bef3-99774ac588bf    b4e9ffd0-976f-492a-8324-5bbd870e2e19    bf5b8d2a-33d2-456b-a51c-70d099e69cf4    e8483047-9c30-4a53-b220-9a78857f4515    2026-04-30      \N      2026-04-30 06:45:32.931807
8392b169-716e-4c0a-9a61-c14599d02df9    28925223-03f6-48ec-8e93-219596159d5d    4d6578b1-c138-485c-b723-09769b46bcfc    493d93c8-a206-4b84-a565-31ce54fb3031    2026-04-30      \N      2026-04-30 06:46:13.862944
c83dd48a-d777-44ec-b151-5286c08a9c9f    ec25a7b6-fd7d-40f5-b771-bd1f083f3525    3b76bd0b-a589-48e3-b4f4-d1edc8d470c3    fb57ff0c-df62-4858-abae-cf4ec4e3170c    2026-04-30      \N      2026-04-30 08:12:11.605826
4e686cb1-e678-41c0-9f6a-362e810cf014    01b2c104-a7ce-487c-9a6b-77d815d57dad    bea61a27-3e66-4b09-93a4-c4a9c71ccde3    99a9b749-b3b1-40ae-98cc-a59a08fdf79f    2026-04-30      \N      2026-04-30 08:14:17.638459
8347e4c3-b966-44fd-942c-45ebcb8d0b89    6f387363-b896-4ccd-8019-2efb7c3227b4    64f0eedb-b654-46fc-8f3d-4319f622d1a8    f1c38418-c8c0-4483-bf87-a851e13619aa    2026-04-30      \N      2026-04-30 08:16:00.552486
c68c8c59-41f6-4a3f-8507-9b29298cdb9b    cc3a2e05-86a2-434f-9e32-fed376886edd    6f1e3154-14a1-46a8-9faf-ee69b96a2371    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    2026-04-30      \N      2026-04-30 08:16:52.029015
1cb8d79a-e310-4848-a8d6-c18e016a4164    3680a313-2b02-45fb-92ed-65d918b9fd63    8da786fe-daae-4d48-8e91-8917843fbff0    09264a61-0b3c-41e3-be12-160077b0e7a3    2026-04-30      \N      2026-04-30 08:18:06.861603
342edf7c-9a3b-4be5-8685-4260f770b749    cfb5dbf4-9e82-4a73-ac68-903b5c34be3a    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    830babf1-8dbb-4061-8a4a-c44797d113af    2026-04-30      \N      2026-04-30 08:19:19.480078
b6f8cf32-380a-4985-b2ff-dc69fd309b4e    b119218e-858a-4c49-a7e6-922b8867bd3a    85c97dd4-67b6-498f-9de5-fff42a422355    dd15bef2-8ae0-4f37-a97b-5e6267616863    2026-04-30      \N      2026-04-30 10:50:37.276281
7531cf04-7b22-4b6a-a285-ce9beb7215e6    8333f845-50bc-486c-a59f-49ff8f1eb377    5ab71d0a-d790-4b4b-af08-ce24ad7773f7    1a07b38b-dd8a-436d-acd9-c187de153ac0    2026-04-30      \N      2026-04-30 10:51:03.375
a8ec60b6-8d64-4e0d-acf9-1999a9fb5443    79da59f7-d58a-4792-8285-f4b2903debb0    fa4ba72a-c067-4cbb-b86a-7e4cf8db638f    51f2090e-54fe-4c1a-82d2-b81b5b883dbf    2026-02-22      2026-04-30      2026-04-10 13:31:50.530983
89e3bbb5-0911-4186-b92b-ab9b7ec37ffc    79da59f7-d58a-4792-8285-f4b2903debb0    fa4ba72a-c067-4cbb-b86a-7e4cf8db638f    c65e130b-82df-4aad-9207-ecf941199738    2026-04-30      \N      2026-04-30 11:36:28.719134
18e1114b-52e5-4182-8327-c0bca3e2f87d    98176849-c1f5-4bbd-8041-c9b4f3270c44    0a59f5bc-3e6b-48d5-96dc-854516f946fd    51f2090e-54fe-4c1a-82d2-b81b5b883dbf    2026-04-30      \N      2026-05-01 08:36:53.770372
6015a728-a7d1-4389-a7ee-9234524409b4    68358b63-163c-4e04-89b4-0b875713c96d    07fef069-8487-4048-accf-5b02bb6ec36c    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    2026-05-14      \N      2026-05-14 11:19:24.560068
f027aafb-e162-4311-a7cf-9c67347c3566    19397653-4da2-40f5-a33d-1fb6350c2cb5    74d687bb-994c-4873-989f-c11f7139f3e3    7842c10d-d9af-4a31-bcb1-c3991a8644ba    2026-06-01      \N      2026-06-01 06:24:02.27299
e269828f-8067-443c-b7db-8db5ac7ccf59    0e5b97e5-d40c-4441-af32-7e0c0b4ebeb2    e7b9bb69-32d1-4bd6-af0b-361b1ae4d451    0ee5fcb6-2aa6-426a-9cf8-ce41f46d4d23    2026-06-01      \N      2026-06-01 06:46:56.953393
e72fc6dd-ef2e-44c5-a97e-11da47353b75    d0cdf354-5cf5-4ab4-bb91-f678eb63637c    230c99e4-75bf-45dc-93f6-2e9aecbbbcaf    7a08de89-a9f5-4dd5-8b1a-6ce585b57e76    2026-05-28      \N      2026-06-01 06:48:55.646437
655a94b1-a682-4cc2-b8d9-2d5082413e29    8e4e40ab-9a5a-47eb-b8a7-601eed34fe70    6bdc52b6-7ad4-40a7-9cef-5df5e4b89d1e    c305222c-ef2c-4cac-a860-53617169f789    2026-05-28      \N      2026-06-01 06:49:06.375046
22041cd3-cb9e-4862-a85f-5c63440bf81b    4291bb46-d0c8-4e02-b3bf-4e8e8fd688c1    70520442-1ef3-4156-94c1-aec49d4bdf79    201edc18-e979-4795-9396-e11f7a579347    2026-04-01      2026-05-25      2026-04-28 06:33:27.365506
10e9a5ce-2e79-4698-adfe-ba3802b67d83    4291bb46-d0c8-4e02-b3bf-4e8e8fd688c1    70520442-1ef3-4156-94c1-aec49d4bdf79    201edc18-e979-4795-9396-e11f7a579347    2026-05-25      \N      2026-06-01 08:45:19.885664
\.


--
-- Data for Name: horse_ownership; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.horse_ownership (id, horse_id, customer_id, created_at) FROM stdin;
82a2997f-207f-40f8-864c-9ed9c33ba140    01bfbf87-18cd-431c-9a7c-f42f96325a3b    b065bed6-7425-4e0f-8607-7ccb8b8c61c0    2026-04-10 13:14:26.374646
9c3a5410-9e34-411a-aaba-b23660eb21e4    e1e41d98-d4fb-44f0-b70e-85c11756b17a    b065bed6-7425-4e0f-8607-7ccb8b8c61c0    2026-04-10 13:14:48.990189
0e934499-123b-4eb5-b029-4a9b0eb368e1    fd18ceff-2c9c-4a44-bfd0-a060d249d617    8cd719bb-46a3-463c-be83-24ae1928f357    2026-04-10 13:17:02.421415
adbafc93-2a81-4ce9-bc46-f6cd9d24e1d4    cc28fa60-c199-4736-8409-5b950cf6b425    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2026-04-10 13:18:54.293517
078c7286-2884-4a69-ae0a-1a59df006918    2328687c-cb15-44cd-adde-141b6d283ccb    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2026-04-10 13:23:45.836426
bdcb5369-d8cb-4d4f-bc4e-e62ff7752a24    c3cf1475-cef0-4166-bf49-601a888453cc    b26abac0-0aa1-438a-9023-fd0e36882de7    2026-04-10 13:27:36.734154
34f1eb95-0537-4edc-b346-fd3b26812407    fa4ba72a-c067-4cbb-b86a-7e4cf8db638f    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2026-04-10 13:31:10.697466
25d349c0-c39d-42cd-9147-776673252fe8    ae00da66-b9fb-4874-93d6-802223ac2c80    8ed90e29-86b0-4cfe-a131-c06cb7413956    2026-04-10 13:39:01.733948
5d604bcf-cfb5-44c6-b702-c2ccdc9a4d1c    97b4bf68-b6e5-4942-8b6e-5f416a726302    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-10 13:41:40.421835
18658d52-abc7-4768-ba4e-d3015c270104    715001a4-6f81-4557-b7b4-4603c367c922    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    2026-04-10 13:53:12.019324
6a1e37c3-d8e4-4cc0-bd8a-c11cb59b2587    98578b91-c647-4d6b-baba-9bd4f6aa591a    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    2026-04-10 13:58:23.652533
9bfb0050-b392-4592-a06b-04ab9c0b345a    ca31a3b6-1260-4142-a1d4-7ffd71b87a80    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-10 14:02:26.336479
89501cf4-bedd-44c9-ad34-b4a495d70808    5d67e9af-fe4a-4666-94a3-674f6506745e    0e868cbd-6f1f-433d-973d-8d44728a7d58    2026-04-10 14:04:28.014814
1b9f4e0a-fa21-43b7-8f5c-9372665b8fb7    4aa7bb18-d21f-421f-b2c0-8cb7ca16ae90    69f1447c-0580-44d2-a699-f4dc2ce56ee5    2026-04-10 14:10:30.164203
05b0025c-38b6-48e7-a9db-864cf7743fb3    ea15f29f-4aa5-43a3-9278-52ed34e73eeb    1e44b508-ea1a-4085-a7d8-91bf6035bfc8    2026-04-10 14:12:09.466615
a036dcc5-e823-41dc-8436-44b5d47f9be5    0762095a-5f68-4b59-86f2-766cf9ef2c69    e2c4ce13-deb5-4561-bdeb-504e3c5f7266    2026-04-10 14:14:16.28738
9072fd45-855c-4cf6-8c41-a33153030d46    b5b72cf6-6d71-4831-9699-8f71570787cf    1e44b508-ea1a-4085-a7d8-91bf6035bfc8    2026-04-10 14:15:34.750748
a5ea6649-cc42-4deb-89d4-871949fbd15f    01e81231-bb91-46ef-b8de-4ad8c1c5fe28    3e04bf98-2062-484c-8832-a6ac763fb9ac    2026-04-10 14:19:05.784777
390a2a72-40ad-4ee6-929d-e2c6b3cc2be5    954d068a-4eef-4a26-89c6-46c7eaebd19f    221c65cc-86b4-48f7-8e6a-098b2b894273    2026-04-10 14:20:58.881627
5f467ac2-dd49-4793-a643-df4dbef83048    9e2813cf-e97b-4a4e-80a9-1352ead28d94    fd7cee81-6479-4a50-89b4-89b4d0354383    2026-04-10 14:23:13.289943
2884d5b3-2069-4ee2-ab00-2b654fd7e966    172f33d7-8431-40fc-84ee-2e35db6094e0    c516087b-5ad6-4896-a90d-b865713b411d    2026-04-10 14:24:41.234486
3e34136f-0822-495d-ad30-cd31b3368621    cfcf58ce-a85b-4619-b232-b48c2b99b562    c4a090cb-0a94-4f14-b303-fbdd506bf56c    2026-04-10 14:25:37.80745
9ca8f175-efd8-4555-bfa4-607a4b9b3b01    5d79a957-f397-4a34-a645-03c5334fceb3    c4a090cb-0a94-4f14-b303-fbdd506bf56c    2026-04-10 14:26:26.306378
f9c9d499-492b-46f4-a2ee-242815024cf9    579743ae-5195-4dca-9aae-ac0f5e9c999b    05805800-43a9-43e0-837b-16c566ed2767    2026-04-10 14:28:40.149614
306d7f21-174d-4f70-a84b-3204fffe254b    7777790e-5fa9-431b-a7db-fab89730eb7f    05805800-43a9-43e0-837b-16c566ed2767    2026-04-10 14:30:03.732009
c4badd4e-0ac2-4088-937e-c47603b430fc    c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    2026-04-10 14:35:27.996198
9ea33c83-88ef-4c8a-ad55-ae5cce1323aa    36e4db8d-0529-4432-8872-6b34980cd0b4    8f423989-21f2-46e2-adf5-6c47f716f5af    2026-04-10 14:37:06.137131
58fcba53-7c9a-4ec6-a860-fd2ca49fc2ec    7fbdf19a-ea91-4a99-a23b-03a7727dd6d8    b6d8a1ce-72af-4a68-b544-0cd212191cc2    2026-04-10 14:38:10.08038
42f40122-6079-4530-b2b3-3c662fdc2c3c    3388f460-d815-48fc-a427-1289adc0ea2f    1c291ce0-4b3a-4765-a88a-6eddae18455d    2026-04-10 14:39:24.422402
748efc6a-1978-4c5f-a42d-2547759dbba3    19055267-8534-43b8-88ee-a303a114c8de    8f423989-21f2-46e2-adf5-6c47f716f5af    2026-04-10 14:40:20.920204
5d4b1437-b0cd-452c-ae0f-2fe585519f9c    77c11e6d-5270-48e0-a0fc-75e34e6a8e95    1c291ce0-4b3a-4765-a88a-6eddae18455d    2026-04-10 14:41:51.499839
44e5213c-785f-4d6f-b533-4a912760667a    469b0c8b-03d9-47a1-aca6-57d0da2ff468    f7fee818-ae88-449d-aecb-619f7f448da9    2026-04-10 14:43:05.377537
cbbbdc97-62ba-4e6f-a707-e83cc92c0f20    3193395a-d8a5-453c-ab8f-3674d4c5b4b8    1c291ce0-4b3a-4765-a88a-6eddae18455d    2026-04-10 14:46:31.912605
7e8f8bc0-4b46-4861-944f-2fda2cf98e83    d1bd0d41-d836-4819-a121-067d370a6365    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-10 14:50:51.622179
6b9b8646-1459-4993-ab4d-7bf8cac875ed    7e7bd2a3-b4c7-4d0f-a476-f05d74f5825b    fe065f3b-9eeb-4682-827f-6f2c25743883    2026-04-12 07:33:41.605255
70522d65-5eb8-48f3-a92d-cc5e380f0669    94b162e6-a9ac-45ae-8411-7c430256474b    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 07:36:23.560728
12195058-6cb6-433f-b69c-8d73d077fd1c    ab89b82b-0bbb-4ae4-91c5-c942f5e53bbc    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 07:37:42.774395
03215ea1-07db-47bd-b9fc-782b43636252    572fe76d-fddd-4422-ac7d-328182d752af    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 07:39:24.769384
d70c8d69-011b-41fa-a925-acf5fb18f6c0    b888a087-a089-44d8-ad06-4cf1f2215337    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 07:41:14.543686
2c93decc-d559-4f78-8ba2-ae69249636a1    52f2e259-349c-4055-b3de-6bdc4b107345    4fdefbef-e962-49a6-bf13-038702cc3fec    2026-04-12 07:43:00.101483
47a9d041-fe0e-4238-b933-e0e335380cf9    05094d8f-70e5-4baf-bf3d-f152d0cb0193    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 07:44:01.720502
f6be8597-2784-4105-9302-ed00eb107900    e49738e9-8f0a-4226-90ee-161f2896cc6a    bfc896d6-ea39-4ddf-8d92-0fbb1762ca04    2026-04-12 07:47:15.851587
3285b50b-cc1c-4d8b-a370-29606965e471    0a87d9f1-9a42-42e7-8062-52f03d34db3e    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    2026-04-12 07:48:43.263656
f2394618-d850-423e-8993-8f77afe6e432    277654c6-5920-4d72-904b-0bac576bb7c1    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    2026-04-12 07:50:49.035225
8efd98e6-c374-479c-bfc1-2d0bf5124d10    b01f993d-3701-4f15-a873-a7c3b8662689    3a68c9e2-1088-48d4-b3ff-17231f380ecc    2026-04-12 07:53:56.133212
8a081ac3-c5e7-4871-9ed8-6414b5fe229d    d5bd7ece-ce0c-4ed9-accb-41b61a45f9fe    1c2d7b81-15a8-4f2f-bafd-f907041a1eb8    2026-04-12 12:38:54.859378
e7c2cd38-f682-4e24-8046-ef1d4e78d286    6ebda625-0073-4929-8dc6-be1f11b77dcb    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 12:42:23.835119
fa7aa665-d5d1-4ac7-a4b3-38c69cfa5f72    b3b2064b-9d98-4f00-b9b5-92d551ccc0c4    919286ed-0bd5-482e-b7a8-75c925386a41    2026-04-12 12:45:01.902383
a107296d-0d47-4fc3-bce8-4c41f75fdb7a    44cd7916-a904-4878-a7ed-204b372246aa    a6aa0f45-4b7a-4657-9a53-e80c16232d05    2026-04-12 12:46:53.709351
96147e0b-f744-477c-874d-cadb36cf9ea4    7a443e5b-439e-406d-9071-7cb8bad8f55d    4939968f-1b46-4d2b-83ed-7c1a29806579    2026-04-12 12:47:55.385287
e9588b91-ae01-4613-95f5-a02bccbe4852    9db24d66-dd17-4bc7-b792-28ce08cd0462    e151d01f-d544-41aa-9ace-ffc81e3ce21c    2026-04-12 12:49:30.562943
38c91d82-a749-433e-8cd6-895dfaddd153    e0835fce-47bd-4f05-8742-539a39282951    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 12:50:32.232581
72b7208f-470b-4b28-868a-089f69750fae    5ab71d0a-d790-4b4b-af08-ce24ad7773f7    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 12:55:20.937217
423c810d-d423-44db-b397-8169f6cc4689    b612fd91-53b2-48ce-bc9b-d3f8203c60e0    b90e3585-1e2c-43a7-8116-3792346ecb73    2026-04-12 12:57:29.684418
6627ff26-3ece-4d94-b678-1740997fa2dc    2416c8c8-cd59-471f-a486-907f2f6e6fd3    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 12:58:37.366175
1a0e6feb-4ca6-40d6-9f17-f2b1c6ec1329    c04bd1f3-aeff-4914-be91-46d11076568c    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:01:12.317465
86ddf717-c2b4-4c5d-8b48-95a06dffa8c8    1ff9dd76-62ea-464c-8e5b-d0ef554af4f6    d4ea9dd1-7189-4a84-ab87-e0ae0a8dc19a    2026-04-12 13:02:27.754495
21eb8833-0a6a-450d-a2e9-a166c41fbbe0    ab2fc725-da06-46e6-8b5c-6f900d7c4e8a    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:03:35.775231
50017d0a-1c5e-45ac-bb83-608bfbae1016    2a567155-2e2c-4153-9257-4b971c12113c    da6262e1-4a7e-4f91-941e-76f3841efc2a    2026-04-12 13:06:12.088043
9c846123-2a17-4c2f-8b17-025ae47bc398    34e07531-488e-4e26-bf46-b156f5c92376    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:07:07.51161
559bb425-5485-4e30-ace2-f33124ac01a8    8d77b2ca-3a06-4397-b4f1-82940b0cd471    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:08:09.657186
8eeb62f8-11eb-4ee2-906f-9b8b82c42e77    265dc87b-8136-4af8-bf84-15cce35a2a08    53188f5a-025a-4154-b876-5e4ae1f220ed    2026-04-12 13:10:15.376658
61c8bda5-c4f5-42b3-82ea-32bd679a2a24    370ada88-9266-4154-ae13-35e8726bc871    53188f5a-025a-4154-b876-5e4ae1f220ed    2026-04-12 13:12:04.678771
5618eb24-8a02-47e6-b9d3-c00ee682654a    dd16f58a-048d-4e3c-9d49-8e5fe253136a    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:13:19.011717
54a0951b-3674-44bd-b94a-0aac859563b7    3ebae8af-8b4c-41f4-8dd7-865708466f62    e6d95ffc-10c1-499e-b300-17235bcb2aee    2026-04-12 13:14:58.190859
e80d882a-fbf1-4b3f-b91b-29398ee5fcf9    8b29306d-783b-41ea-b521-7e671b855687    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:16:04.122924
c61def32-0fdf-4b99-accf-55617df46cfe    8163b10e-1308-442b-ad73-43dac0f0206b    e8918c53-5c87-4e2d-86f9-91276d63bf0d    2026-04-12 13:17:29.455299
29a2081e-fd91-49a7-98b3-12213de62c1a    04edebe1-cf3c-4e57-8d06-74fbfc443930    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:18:09.498246
0e215d0c-8794-4096-a9da-479e897bdb4b    28f3fbba-d41a-4c88-ad2e-09983513545e    fe065f3b-9eeb-4682-827f-6f2c25743883    2026-04-12 13:19:57.319706
21ceff8c-09a0-46ea-b8b9-2b58c24494ac    b22b322c-6035-4697-9309-c8a279786522    369d0d0f-5c75-422f-b983-695a04a7f883    2026-04-12 13:28:13.919081
d6f45d86-9566-4344-ac73-9ad553d74065    683d28c5-09ce-4886-adaf-c2378c3ad86b    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:29:21.031396
e4dbecd2-caf1-4a3e-acbc-abcd2017f2a7    9f2b32d6-ea20-4dcd-be1c-08e33d516b43    7f34854a-d81f-40ff-b4ec-b2671dcf95ff    2026-04-12 13:30:54.434809
cd755895-aeea-43fd-b932-e64662b11a95    666f76e1-0fe1-44ca-86e5-d2d79f2058aa    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:31:57.043236
dcdec2a0-2fa6-48c2-82a3-e9efad381b5f    d1a9475d-30f2-4565-b9cc-cb47486d4370    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:37:13.035611
4ef723b5-3f17-4573-a6d6-e983524314da    e73a0e9a-1518-435b-92f4-81c6d1a2570e    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:40:19.27068
5db12bfe-8c65-40c6-9261-ddc0ea47f289    e38c9510-b163-4946-9c70-cbc41e33d2cc    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:44:57.67949
a7d25021-954e-4b35-9f35-6354754f3b30    2a12df79-2327-4240-8140-63b6eeb3b1c8    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:45:41.697414
993388b0-a82d-4fa7-a138-ff2f68962fa2    ba17ad82-0b0f-4b7c-ab76-ef1a1eb41901    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:46:44.380736
35b269aa-6127-4785-8eed-f71e95e12adb    e67173c3-b0a7-47c9-a703-b82fe0d6d0d6    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:48:34.185094
9d7bb3d7-3f2c-449c-888a-57f2390c0bd8    5b8b8905-f9b8-4331-9e78-b670baa9e790    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:50:10.766466
e69839a2-8a78-4105-9511-93fb469ec004    2ff25291-c7b6-4e4b-91c2-d4244b1123fb    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 13:51:42.659219
80c76c22-27c3-4a16-a07e-456e143c04df    6aaf4500-ea31-4dd6-beda-63f91e2c1712    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:03:04.442314
b99be630-ecd2-4768-8c2f-dbd1f394f784    c23f295d-2bee-4c15-9c2f-0ca3e1d9143e    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:04:11.636574
d7bdbb85-87f0-4c2a-8221-e6930ddbcae2    08568f63-6a52-4dc7-9553-8882ea1729ee    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:05:04.059501
5cf83f43-7b0f-4c6b-8923-65ee866a1eb1    1cfae32a-2431-4b86-8e1d-0aa13b0b7578    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:06:58.152411
55a2482c-d86a-4dae-929c-7bdfda65381a    05bf209f-ac57-4075-b11c-b31cb8da1503    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:08:21.110626
e316f8cf-043f-467b-b7c0-2fd463d58e9f    c16c4cbd-3c0e-4129-97e2-a14cccb86bd0    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:09:56.451791
6650dbb8-4258-49b0-84a1-a62cda0c9b50    8df73a20-0b00-4222-8a62-53ce516a7201    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:10:51.48327
998e55fc-76eb-4232-959f-03e53fbe39dc    b77ae74e-6068-48a4-ab38-4a321d6ee2a2    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:12:02.875127
c775e9cb-5173-4fc5-82b5-0ac86f2f6ce6    f378c4d0-9cd6-4507-a22e-3327f67cb27d    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:13:11.664333
09590004-15c7-4217-aff2-1322abc1056f    0e711139-3a00-4a45-b7fb-53b8c53679ba    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:14:22.264098
8c7964be-8f80-4572-8672-93654a1c2d31    d4b37e9c-0081-454f-a718-af4cdb007f81    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:15:46.624245
04b8a4b5-8eef-4587-8893-4f0fad847920    26b53768-699e-4fe0-bb45-e0cea76461d4    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:16:53.289001
95cf9ff8-cbf2-4800-a4d7-0f9f462477c1    694a552b-db84-4e21-88d2-218c6de7fb4f    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:18:10.223131
221fae66-589a-4dbf-8fa7-ac941d7cfa22    5c489303-0640-4eab-a8cb-dffdf2200f7a    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:19:13.047912
567e009f-f9e1-47e5-bc7c-4ea8f469c0bf    1f9ba834-2060-4c64-b3c4-e85d2d90c8af    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:19:52.056234
66c648e6-2ee7-4c7c-bb97-9afe2327b17a    d4f83442-a140-4edb-9ae0-fd48a9785d91    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:20:38.179833
97c22759-8e7a-4c09-a41f-ccd850ffd5a5    707d8ed3-9b2d-4e0c-b5bd-4f03174f49ad    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:21:35.196449
ebf17f6e-d0a2-4a8b-a402-915100b067d9    ebd1fc51-94d5-4dab-b25a-34e7acf799e1    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:23:38.855112
68a5400f-2b9d-4e12-ae2c-8e1fcecc4b46    512ab1bc-a848-429a-9087-17d7078681a0    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:24:51.047651
c342398a-a5ef-41f4-aecc-51a3c5b1f9d7    60ac0380-e9e3-44d7-b358-1886264a2b00    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:25:38.813986
24d5d3fc-30ed-4c9d-ab26-96309441c9e8    971b1adc-396e-44ca-99ef-0fd467f9ac76    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-12 15:26:55.442098
3d05b211-9489-4c67-80d7-bcce57012e88    9dc9c619-b7c4-4395-9920-9bebe2adf29d    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 05:52:08.016232
9c45d873-2a3d-4a8a-a65d-751162ce23fa    b21d3c3e-0f48-4d89-ae09-3479eab4ade8    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 05:53:31.126317
97215531-6cec-48a4-bdfe-58666e4d6b1a    11d1ecad-f343-4fce-aaf3-60fa983f9b79    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 05:54:37.818611
84f616b9-0c89-4497-a15c-16102e021e7a    b0ec4749-710c-48fb-9016-6db48202040f    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 05:59:54.88578
5c087c0f-cade-453f-bc63-543bc1456925    a910888e-eb39-491e-95e4-5a1a338efe4f    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:02:02.725715
4c5064af-2116-43d7-93a0-2658de30d99b    bc785f1a-5963-4c21-9d34-b7fbc01674b1    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:03:07.466564
5a1d7181-92a9-41c0-bbec-f283a3a2f6cb    88f847b6-caaa-4736-bee8-13ff4caf88b7    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:07:23.204163
e505b2bf-7260-4b59-aae2-7ed32897fa3c    1abc3ea0-a055-45d2-9fd9-ff3da182e5f5    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:10:51.026024
02ba554e-3028-4b84-95cd-a05bc59a0d3f    57e9d488-fa06-49ff-a829-565080196562    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:11:39.87571
ca2e7160-6b2d-4778-b2a5-4f2375bbd9b8    275c4ae5-fd82-412d-a07d-334e94f6a46d    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:12:42.693765
ea0770ea-d34a-4cb0-8755-6670b7adeea3    f73bc29c-b715-4968-b437-51302ec39fab    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:14:10.090514
6b20117e-7174-40bc-91c6-cce9eec80976    9c27b6eb-248b-4d56-a688-ec67330a0ad6    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:14:59.517396
2bcb900c-e9b2-4241-b110-07002a1b3f72    323c54ba-b227-4807-b018-5c47f05caed7    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:16:31.587883
0996220a-7749-4083-a876-49431e3bb244    98e66e07-9adb-46c1-86ee-0bd6d16b8f41    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:17:31.786649
4633572f-262e-49e9-be41-7dedf3bd0c3a    49800c23-738d-4282-8a44-d1a4ccf11e63    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:18:28.625665
b7375b5a-0a0a-42d9-8e98-334847cbfdae    8a8720a8-a9de-4f04-875f-449ed3af9556    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:19:23.397142
4c5e368e-c19d-4541-96f6-a2f4307e49c4    fc513ffa-ebf2-4e26-b9ab-c0449ac1dccc    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:20:08.959731
28f398e9-abbc-4ea6-a103-d047e1851640    e194f17a-8924-4f6a-8a05-96a152a43a74    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-13 06:21:13.671004
fd15b757-3fbf-4caf-afbb-67c16d4da817    0593cfda-a5bd-4fea-a12a-7a0434121eb7    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:11:51.844298
9dcc97cf-b489-4969-b340-8d69a9d8c795    cc2fccde-6e0c-4f23-bd3d-b1ec586c4c5c    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:13:17.02536
bec1d3bd-6ed0-430a-a4ed-a0100a2b1e6f    d3ccaeaa-0818-4e87-86b3-3f4602fc27cc    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:13:28.97396
85da7578-e6fd-4de7-9c0c-80fe191dc8b8    aca66b02-174c-4e6a-8b39-9469dd117676    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:13:48.834084
ca5fff6e-473b-4471-b7e8-22882069b66d    699ff103-7bd0-4866-a818-2a0b3d3ed141    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:13:58.379118
8a57e542-50b3-4bf1-a3f4-a178cbce3dc4    c86b80d8-72e0-4795-b9fb-63918cf78ad9    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:14:10.935616
a1a4a8d0-292e-403f-842b-c9afd52cc5e0    90b2f161-1add-4428-a2b8-b1808dddb803    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:14:24.244296
4f675ef0-5365-4f61-ac52-1359f87f33f9    217838db-92a3-4f51-b25a-ee20901329ec    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:14:41.194969
d359f9d0-1268-4ae9-a66b-21395f0449a3    1c9d36f7-0f9e-48ad-b6ad-471002e4f78d    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:15:09.707573
660cabd1-3dc3-4cf8-bd35-245d5ec07b9f    5579fc44-2611-4b72-9ba7-46b5185f8415    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:15:21.046289
a8c2eb31-2b1a-45f8-94cc-d25b57f6ceb9    70520442-1ef3-4156-94c1-aec49d4bdf79    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:15:32.703905
d0e97e84-87b3-45b4-a3e7-3fecbfd0cabc    7a2aaa8b-e1ff-4ba8-b9bf-feda58967f24    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:15:41.253344
f4307ec3-8ed8-45c2-8149-bceee91ec25a    f47e1e18-6c49-4a0c-8134-24d99f082763    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:15:58.262236
9c230386-4042-4c53-b866-d627186726c6    cf937986-711a-402c-87e1-66c76e50576d    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:16:07.381374
9d323f22-006c-4151-9b12-1e1208b3d6f9    169eafb1-86f1-40d5-8fae-095a64208fed    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:16:21.227316
4ad258af-5c80-43ed-9984-9995afd14aa6    68c49dc9-9880-4115-99a6-c8dbd28b760d    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:16:31.196354
d33b2b31-1ab5-4b19-a0c1-d16117b2bca6    463b1dcb-92a6-47a1-9573-a060d41e258d    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-13 07:16:41.548972
c82e4fb4-f5c1-442b-8672-0ff9dcee54da    50961ee6-cf34-40ee-8bdb-d37f55069ab6    5f217e94-85d7-47aa-b137-94a3c293c35c    2026-04-13 07:56:12.468997
79e3f5d1-423a-4a88-95fe-88ed5199050b    ae794684-5b89-45df-8879-23139afc992c    5f217e94-85d7-47aa-b137-94a3c293c35c    2026-04-13 07:58:24.650481
d6398143-370c-430d-b6df-6242b925c7cd    bf5b8d2a-33d2-456b-a51c-70d099e69cf4    5f217e94-85d7-47aa-b137-94a3c293c35c    2026-04-13 07:59:58.595193
3f0af71a-ab46-4e01-b10d-352b2824f5bb    4d6578b1-c138-485c-b723-09769b46bcfc    5f217e94-85d7-47aa-b137-94a3c293c35c    2026-04-13 08:01:47.94965
4a9ac058-2f23-4135-b36e-f817abf4a9c2    3b76bd0b-a589-48e3-b4f4-d1edc8d470c3    b98e1c14-1b11-4953-b795-ff41a2042572    2026-04-13 08:03:08.603005
f5bd990c-0046-4f67-b12a-aeb0bcb3447e    bea61a27-3e66-4b09-93a4-c4a9c71ccde3    b98e1c14-1b11-4953-b795-ff41a2042572    2026-04-13 08:06:03.174637
1b9cfb0b-57d1-41ae-811a-b9d7a98506e5    64f0eedb-b654-46fc-8f3d-4319f622d1a8    b98e1c14-1b11-4953-b795-ff41a2042572    2026-04-13 08:06:31.349789
4ebcfdd9-0e45-42ad-991e-ad61712cb5ac    6f1e3154-14a1-46a8-9faf-ee69b96a2371    b98e1c14-1b11-4953-b795-ff41a2042572    2026-04-13 08:07:01.599196
38f89b2d-8b4d-4972-a355-9ab9e10f4106    8da786fe-daae-4d48-8e91-8917843fbff0    b98e1c14-1b11-4953-b795-ff41a2042572    2026-04-13 08:07:39.668729
3027cc0f-1836-426d-b08b-51efbc9a43ef    6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    b98e1c14-1b11-4953-b795-ff41a2042572    2026-04-13 08:09:21.50966
3a2013fa-52e1-47af-8012-9971e8b8109d    31cae8e6-e114-4aad-9715-895c850f1ee0    af441b86-4b9a-4810-9cdd-7af4f886aef6    2026-04-13 10:44:05.078358
76709e30-0a27-4dda-89bc-64d8fc267b21    b189c9c9-5544-489e-a977-0efb23c28182    3901dd23-92c5-41d6-9b65-b4b356d1d862    2026-04-13 11:17:49.927847
24801f01-673c-469c-bdcc-0663daee1332    31c8d10a-4c86-4312-b87f-789bb093ae64    3901dd23-92c5-41d6-9b65-b4b356d1d862    2026-04-13 11:18:41.494162
25572077-7ba5-4f6c-ae49-1d5375d2235a    dd6d2609-8347-4a17-9601-deedec56b013    0b7d70b1-4e87-4be1-9d49-d61630dd7284    2026-04-15 18:13:28.089338
ba53aa53-6de1-4307-b115-bc867dd8d3c9    cb2f6594-987d-4c21-a0a0-546e6d79fe07    cf86fecc-4a1a-4ba1-8e60-a9818623ccb2    2026-04-15 18:16:42.127497
678651dd-62f3-4d30-8a6f-046bad3dce4e    c7015dfc-588b-42ec-9da4-3b57d5ef5c76    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-15 18:30:00.638831
a88ef7ce-a923-4e8b-b448-81e6154c1fd2    17803d95-b55c-4ac0-817c-708b70402f7c    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-16 07:38:30.449686
5b8a0564-ddf4-41be-a6b4-5a665e75d5be    b36676ac-3cf0-4f4e-bc3d-390a4b9872f1    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-16 07:38:48.594787
b2239d36-335c-4a98-85c7-b6adc2030caa    48905175-9060-4c4f-ae93-5ff894fa7786    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-16 07:38:59.984753
d528d532-9b91-4049-b22d-1eba3283a28d    85c97dd4-67b6-498f-9de5-fff42a422355    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-16 07:39:29.578625
9191e953-0c22-4cc9-8e79-dd54cfca0385    25dfa570-fea0-4e28-bbe0-82beef1dc3b8    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-16 07:39:46.633848
570319d0-4ad1-49b5-9907-988aad8c6c27    8c494095-f2c7-4e6f-8063-3b67bca9871c    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-16 08:15:45.214237
c9cde7b3-843b-4dc9-a3a1-1fe0fd15e503    e3386a83-5edd-4f6a-940c-a1632dcb00d4    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-16 10:28:56.298236
13f1f075-70a8-4261-9106-30ca7a50795c    55e391de-29b6-4212-9c50-2cf029406e87    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-16 10:29:11.434559
3d30cd61-f52b-46d7-a546-5a4cde83ea2b    6bbb13c3-5d69-4fe4-bf1b-c04938c81f5f    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-16 10:29:35.28537
b7dc1c8c-1103-4860-bd5d-a10ed13e088e    c91f1e28-5c64-4612-b74c-ab1f66d4391e    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2026-04-16 10:29:58.081493
cd89d8e6-2a9d-498d-9d76-e586776a92ef    e97f808a-6c4d-4637-92fc-6692db6b8c01    3fe1302f-fad6-42cd-915e-acef194e13c6    2026-04-30 05:47:29.61404
b12e890d-dcb9-4001-bf61-6efdbb4c6233    94f4a18b-0024-488d-9dc6-487620feb8a6    3fe1302f-fad6-42cd-915e-acef194e13c6    2026-04-30 05:49:33.371291
3a23dcb6-cd25-45bd-8906-dccb0430fca5    932f95d6-5ae2-4b41-a034-3b0e99285a22    3fe1302f-fad6-42cd-915e-acef194e13c6    2026-04-30 05:50:43.943668
48470217-50bb-4b22-92d1-fd5e0a01369d    e32704a3-a4a1-4d54-963c-8c777a4ea7cb    3fe1302f-fad6-42cd-915e-acef194e13c6    2026-04-30 05:51:37.954659
bf7a1066-827a-48ce-b90e-ac64876af230    0a59f5bc-3e6b-48d5-96dc-854516f946fd    3901dd23-92c5-41d6-9b65-b4b356d1d862    2026-05-01 08:24:06.46163
76684cb5-c425-4ce4-adab-9dff48126431    55add96b-8f46-4cd4-905b-cb3613d4b244    c0471f15-cf19-4ac7-87da-2931db694ddd    2026-05-01 09:17:13.066054
568a8dd1-16f7-40a3-af03-58502a31bd72    750ac464-8c94-42e5-b7ad-d37df32d7f27    53946bbc-2874-45af-ad7e-6d3d52dc0c25    2026-05-08 06:35:37.237934
d9f07000-2e66-481c-bfbf-2411bd0789f3    3f2b4133-ae62-42e6-91ff-e7d2c4455ef5    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-05-08 06:37:44.979908
e78929be-36da-4482-9889-7b023f063d61    b753fb55-74f7-4ec8-b6f8-98c32ef37aa2    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-05-08 06:37:59.663667
dc050316-5c59-44a4-9e7c-2a4d7c41db0a    2d645649-3681-4c85-bbd5-09d4689b3c8a    297dd6e6-0736-4735-b670-eb51444f8a21    2026-05-11 11:44:19.116506
6a0886ac-391f-4734-8efd-fb2586a68a74    2caec785-144d-43cb-aca7-b72361396ef4    297dd6e6-0736-4735-b670-eb51444f8a21    2026-05-11 11:44:32.664935
8db01627-5e63-4809-808f-594e28c17de3    5358f269-d191-476f-ad0b-0338c795e46a    297dd6e6-0736-4735-b670-eb51444f8a21    2026-05-11 11:44:44.782858
c6712d9b-35b8-46d1-abbb-d3f9bba2deed    3bd0e33d-dbe0-4c57-b684-bdbe04513d7b    297dd6e6-0736-4735-b670-eb51444f8a21    2026-05-11 11:44:54.962153
27ec60f7-af38-47cc-896b-ee311ee1831a    07fef069-8487-4048-accf-5b02bb6ec36c    2ac641cb-e76f-47c1-9361-10488823595a    2026-05-14 11:16:23.283231
92b531cf-60de-43f0-beee-352479d806f4    fd1cbc9e-abe5-446c-bef0-ebd171304d49    dbfc0a19-eb4d-4b1e-8c17-0fbc116e8491    2026-06-01 05:33:29.539629
11f70378-a66a-404d-90db-b3549d318125    230c99e4-75bf-45dc-93f6-2e9aecbbbcaf    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2026-06-01 06:04:10.1167
32532ed4-c307-46e6-bd97-67fea7068cc7    6bdc52b6-7ad4-40a7-9cef-5df5e4b89d1e    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2026-06-01 06:05:55.067946
a9ee8769-053f-487f-a377-af6d479d57f7    e7b9bb69-32d1-4bd6-af0b-361b1ae4d451    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2026-06-01 06:19:47.582495
f8263675-aebb-4e2e-8c0f-392a543b08de    74d687bb-994c-4873-989f-c11f7139f3e3    07cc6f8f-59e4-4d50-a1a1-f2e751b9758b    2026-06-01 06:22:59.566263
f2b90056-0d58-4133-ab23-df1c4f51ba1a    a5687fc6-972f-4060-82fe-21a27ad15812    a19be827-adc1-42db-9b25-fa1a955efc98    2026-06-01 09:51:52.328538
4230b6c5-b07c-468b-bd02-ed36ca72efbd    7be87fe9-3317-4f05-999c-8f7d7acdcb18    1d7984cc-9a01-4a0d-ac67-1e53264ce3a2    2026-06-01 09:52:12.855028
f3818c42-65b2-4c20-9fd2-f92b35d179c2    3039ad2b-6bcd-420b-b809-e42394668687    1d7984cc-9a01-4a0d-ac67-1e53264ce3a2    2026-06-01 09:52:21.766777
21c1f95d-79e5-4b20-8b7d-a1a5833fc6a4    cd4885f5-73a4-4161-bfb8-496b0967bb3d    1d7984cc-9a01-4a0d-ac67-1e53264ce3a2    2026-06-01 09:52:30.52099
71ca0095-e451-4d8f-a9ff-e58860bc9911    00f6f8b5-2ca9-4ba5-9571-9488364c134b    1d7984cc-9a01-4a0d-ac67-1e53264ce3a2    2026-06-01 09:52:40.354621
\.


--
-- Data for Name: horses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.horses (id, netsuite_id, horse_name, passport_name, passport_number, sex, size, color, breed, date_of_birth, comments, status) FROM stdin;
dd6d2609-8347-4a17-9601-deedec56b013    2033    Calvaro Calvaro \N      Gelding \N      Bay     \N      \N      \N      active
cb2f6594-987d-4c21-a0a0-546e6d79fe07    149     Castagnette     Castagnette Vaumartin   \N      Mare    \N      Chestnut        \N      \N      \N      active
48905175-9060-4c4f-ae93-5ff894fa7786    7438    ASH     Ministown ASH   372003006882635 Gelding \N      \N      Irish Pony      2019-01-01      \N      active
c7015dfc-588b-42ec-9da4-3b57d5ef5c76    41      Kulla   Kulla R.S.      \N      Mare    \N      Bay     \N      \N      \N      active
94f4a18b-0024-488d-9dc6-487620feb8a6    \N      Cornet XL       \N      107DN69 Mare    \N      Dark Bay        Hannoveraner    2016-05-08      \N      active
e97f808a-6c4d-4637-92fc-6692db6b8c01    \N      Kasseb  \N      109MY20 Gelding \N      Bay     Selle Francaise 2020-03-01      \N      active
55add96b-8f46-4cd4-905b-cb3613d4b244    \N      Power Presley   \N      \N      \N      \N      \N      \N      \N      \N      active
0a59f5bc-3e6b-48d5-96dc-854516f946fd    \N      LIKE WHITE      LIKE WHITE      DE418181109321  Gelding \N      Grey    Springpferdezuchtverband Oldenburg-International        2021-06-02      \N      active
750ac464-8c94-42e5-b7ad-d37df32d7f27    316     Youpi   \N      \N      \N      \N      \N      \N      \N      \N      active
2d645649-3681-4c85-bbd5-09d4689b3c8a    \N      Dannone \N      \N      \N      \N      \N      \N      \N      \N      active
2caec785-144d-43cb-aca7-b72361396ef4    \N      Carte Blanche AZ        \N      \N      \N      \N      \N      \N      \N      \N      active
07fef069-8487-4048-accf-5b02bb6ec36c    \N      Jourji  Jourji Borget   2500FR19309815U Gelding \N      Bay     Autre Que Pur-Sang - AQPS       2019-12-04      \N      active
fd1cbc9e-abe5-446c-bef0-ebd171304d49    \N      San Merino      San Merino      \N      \N      \N      \N      \N      \N      \N      active
6bdc52b6-7ad4-40a7-9cef-5df5e4b89d1e    \N      Toto Black Diamond      Toto Black Diamond      380007000161336 Gelding \N      Dark Bay        KWPN    2020-05-01      \N      active
e7b9bb69-32d1-4bd6-af0b-361b1ae4d451    \N      Rodeo   Sanays Secret   826006031028521 Gelding \N      Black   Hannoveraner    2021-05-15      \N      active
74d687bb-994c-4873-989f-c11f7139f3e3    \N      Montana Jamaheeyah      KSA02094275     Mare    \N      Bay     Thoroughbred    2021-03-14      \N      active
230c99e4-75bf-45dc-93f6-2e9aecbbbcaf    \N      Pomodoro        Dunarit HB      348001205140110 Gelding \N      Chestnut        Hungarian Sport Horse   2020-04-03      \N      active
a5687fc6-972f-4060-82fe-21a27ad15812    \N      Osiris Equigenne        \N      \N      \N      \N      \N      \N      \N      \N      active
b0be9ff0-df10-4aa0-9c68-f0e85aa633b8    45      Lord    Lord    \N      Gelding \N      Chestnut        \N      2007    \N      active
3984312a-77c3-4315-89e1-5203fd9fe3c1    47      Matie   Matie Du Prieure        \N      Mare    \N      Chestnut        \N      2000    \N      active
5a345f68-2cbc-46c2-929f-ae77a92d81a0    48      Miel    Miel    \N      Mare    \N      Dark Bay        \N      2001    \N      active
5601870a-9718-4b64-a2c8-d50e8b3cc0e1    52      Navar   Navar By Vergil \N      Gelding \N      Grey    \N      2009    \N      active
51da468f-e941-4804-8f10-25331e4eb5d4    54      Onyx    Onyx    \N      Gelding \N      Grey    \N      2002    \N      active
84863fd2-d337-4853-a753-967f4aa27a65    58      Petit Prince    Petit Prince    \N      Gelding \N      Chestnut        \N      2003    \N      active
ca31a3b6-1260-4142-a1d4-7ffd71b87a80    51      Nathan Des Hayettes     Nathan Des Hayettes     \N      Gelding \N      Bay     \N      \N      \N      active
6ebda625-0073-4929-8dc6-be1f11b77dcb    42      Landwirbel      Landwirbel      \N      Gelding \N      Grey    \N      \N      \N      active
971b1adc-396e-44ca-99ef-0fd467f9ac76    55      Osto    Osto    \N      Gelding \N      Dark Bay        \N      2002-01-01      \N      active
323c54ba-b227-4807-b018-5c47f05caed7    9       Baldor De Brugere       Baldor De Brugere       \N      Gelding \N      Bay     \N      \N      \N      active
98e66e07-9adb-46c1-86ee-0bd6d16b8f41    8       Bajeelah        Bajeelah        \N      Mare    \N      Grey    \N      \N      \N      active
b77ae74e-6068-48a4-ab38-4a321d6ee2a2    1       Aceto MC        Aceto MC        104KQ86 Gelding \N      Grey    P. Arabian      2006-01-01      \N      active
8f4a9428-72df-4e4b-b9e5-344707ddea76    60      Prince  Prince  \N      Gelding \N      Chestnut        \N      1995    \N      active
07c95eac-a5c4-463d-a6a5-2f5d7af9feea    61      Quick Star      Quick Star      \N      Gelding \N      Chestnut        \N      2008    \N      active
81c500dc-9316-470e-9af3-722f132a2aa4    141     Rafed   Rafed   \N      Gelding \N      Bay     \N      2003    \N      active
54b9fb6d-75da-4d76-a7ff-5f1860f09b04    62      Rapide  Rapide  \N      Gelding \N      Chestnut        \N      2009    \N      active
99a7d88f-7777-4b59-a604-013d59114111    63      Rock Star       Rock Star       \N      Mare    \N      Brown   \N      2006    \N      active
5d948350-24cc-4f0b-a012-f2791ca50fbf    97      Sabrina Sabrina \N      Mare    \N      Chestnut        \N      2013    \N      active
9fc5df78-1716-44dd-baab-e09f150942a0    312     Macallan        Macallan        \N      Gelding \N      Black   \N      2019    \N      active
bb27550c-b644-4c62-9e10-cadebfd50bfc    68      Sarican Sarican De Mai  \N      Gelding \N      Chestnut        \N      2012    \N      active
30429748-ba1e-4d04-a2e2-e57b5e5eb02c    70      Seekatzee       Seekatze III    \N      Mare    \N      Bay     \N      1999    \N      active
a93421ce-ce40-473e-8206-4a8c94478980    71      Sisko   Sisko   \N      Gelding \N      Grey    \N      2013    \N      active
7f3618ae-4fe6-4d1a-895b-909cff801c92    72      Ta Allak        Ta Allak        \N      Gelding \N      Chestnut        \N      2015    \N      active
779566bd-c38b-4a10-ae22-d1ee6ed5eac1    \N      Archie  Archie  \N      \N      \N      \N      \N      \N      \N      active
8c494095-f2c7-4e6f-8063-3b67bca9871c    \N      Ceta (Cetaloubet)       Ceta    \N      Gelding \N      Chestnut        \N      \N      \N      active
932f95d6-5ae2-4b41-a034-3b0e99285a22    \N      Infinity Wow    \N      108NY77 Gelding \N      Bay     Selle Francaise 2018-05-03      \N      active
93781325-88ee-4408-a593-95fc00268bd7    201     Ulyse   Ulysee Du Guide \N      Gelding \N      Chestnut        \N      2008    \N      active
9ca9fabc-d8ee-463b-9dcd-97b3e70a6dc7    78      Zumurud Zumurud \N      Mare    \N      Bay     \N      2007    \N      active
b753fb55-74f7-4ec8-b6f8-98c32ef37aa2    157     Kiwi    Stockalose Camilla      \N      \N      \N      \N      \N      \N      \N      active
5358f269-d191-476f-ad0b-0338c795e46a    \N      Jack Daniel Adams       \N      \N      \N      \N      \N      \N      \N      \N      active
3bd0e33d-dbe0-4c57-b684-bdbe04513d7b    \N      JB runs with Scissors   \N      \N      \N      \N      \N      \N      \N      \N      active
7be87fe9-3317-4f05-999c-8f7d7acdcb18    \N      Novara  \N      \N      \N      \N      \N      \N      \N      \N      active
8006a019-d097-4cbd-b7f4-3b863df5cc27    2434    Solas   Solas   \N      Gelding \N      Grey    \N      2020    \N      active
3039ad2b-6bcd-420b-b809-e42394668687    \N      Corando \N      \N      \N      \N      \N      \N      \N      \N      active
cd4885f5-73a4-4161-bfb8-496b0967bb3d    \N      Ghawiat \N      \N      \N      \N      \N      \N      \N      \N      active
00f6f8b5-2ca9-4ba5-9571-9488364c134b    \N      Florence        \N      \N      \N      \N      \N      \N      \N      \N      active
b899204c-ecac-4b6e-b785-87629d34d746    5335    Haia    Haia    \N      Mare    \N      Chestnut        \N      \N      \N      active
b0c7dcdb-1a09-4226-8412-9668fa0bfaf1    1834    Campina Campina \N      Mare    \N      Grey    \N      2008    \N      active
a645c81e-2cdb-4d1d-a351-dd109d2db100    3734    Moonlight       Notre Dame 28   \N      \N      \N      Grey    \N      TBA     \N      active
289c6dce-b01b-4241-98af-0cb604947086    429     Cancun  Cancun  \N      Mare    \N      Bay     \N      2013    \N      active
8f4620d4-fefb-4c45-8ba3-83072a61cae3    7137    Forrest Forrest Gump 6  \N      Gelding \N      Brown   \N      2019    \N      active
7095cd67-edd2-4ed6-8562-4b5b7b1c1622    7337    Fretma  Fretma Larzac   \N      Gelding \N      Black   \N      2015    \N      active
692911cb-dde1-4b4a-a4ea-f38059517003    3735    Almastar        Almastar        \N      Gelding \N      Bay     \N      2019    \N      active
5d67e9af-fe4a-4666-94a3-674f6506745e    5534    Ludo Wig 3      Ludo Wig 3      \N      Gelding \N      Black-brown     Oldenburg       2008-12-03      \N      active
c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0    14139   JUPITER II      JUPITER II      \N      Gelding \N      Grey    Lusitano        2014-04-21      \N      active
469b0c8b-03d9-47a1-aca6-57d0da2ff468    144     Sirocco Meraniere       Sirocco Meraniere       \N      \N      \N      \N      \N      \N      \N      active
1ff9dd76-62ea-464c-8e5b-d0ef554af4f6    104     Carpaccia Picarel       Carpaccia       \N      \N      \N      \N      \N      \N      \N      active
5b8b8905-f9b8-4331-9e78-b670baa9e790    67      Sancho  Sancho  \N      Gelding \N      Brown   \N      \N      \N      active
8a8720a8-a9de-4f04-875f-449ed3af9556    146     Wisham  Wisham  \N      Mare    \N      Bay     \N      \N      \N      active
9c27b6eb-248b-4d56-a688-ec67330a0ad6    64      Runild  Runild  250001 05097819 R       Mare    \N      Isabelle        Fjord   2005-01-01      \N      active
31cae8e6-e114-4aad-9715-895c850f1ee0    2859    Valentino       Valentino Massuere      \N      \N      \N      Chestnut        Warmblood       2021-01-01      \N      active
25dfa570-fea0-4e28-bbe0-82beef1dc3b8    12      Bayardo (Bayardo)       Bayardo DE421000509009  Stallion        \N      Bay     Holsteiner      2009-01-01      \N      active
e3386a83-5edd-4f6a-940c-a1632dcb00d4    3       Amir (Amir by Ap Imdar) Amir by Ap Imdar        105LF50 Gelding \N      Chestnut        P. Arabian      2010-01-01      \N      active
55e391de-29b6-4212-9c50-2cf029406e87    81      Bakida (Bakida) Bakida  105AI41 Mare    \N      Bay     Westfale        2006-01-01      \N      active
0593cfda-a5bd-4fea-a12a-7a0434121eb7    169     Petra   \N      \N      \N      \N      \N      \N      \N      \N      active
cc2fccde-6e0c-4f23-bd3d-b1ec586c4c5c    828     Schumann's Eragon       Schumann's Eragon       \N      Stallion        \N      Bay     Shire   2013-01-01      \N      active
c86b80d8-72e0-4795-b9fb-63918cf78ad9    171     Smokey Lady     \N      \N      Mare    \N      Dun     Irish Pony      1996-01-01      \N      active
217838db-92a3-4f51-b25a-ee20901329ec    167     Kromar Al Sheea / Jawara        \N      \N      \N      \N      \N      \N      \N      \N      active
7a2aaa8b-e1ff-4ba8-b9bf-feda58967f24    163     Spotty  \N      \N      \N      \N      \N      \N      \N      \N      active
f47e1e18-6c49-4a0c-8134-24d99f082763    165     Al Aryam Dallal \N      \N      \N      \N      \N      \N      \N      \N      active
cf937986-711a-402c-87e1-66c76e50576d    170     Day Dream Believer / Harry      \N      \N      Gelding \N      Bay     Connemara       2005-01-01      \N      active
463b1dcb-92a6-47a1-9573-a060d41e258d    9437    Falabella       \N      \N      \N      \N      \N      \N      \N      \N      active
aca66b02-174c-4e6a-8b39-9469dd117676    162     L'eclair du Milleron    \N      \N      Gelding \N      Piebald Pony    1999-01-01      \N      active
90b2f161-1add-4428-a2b8-b1808dddb803    172     Lana Al Khalidah        \N      \N      \N      \N      \N      \N      \N      \N      active
5579fc44-2611-4b72-9ba7-46b5185f8415    164     Mickey  \N      \N      \N      \N      \N      \N      \N      \N      active
01bfbf87-18cd-431c-9a7c-f42f96325a3b    15537   Nouar Al Firas  \N      \N      Colt    \N      Chestnut        Arabian 2026-02-01      \N      active
e1e41d98-d4fb-44f0-b70e-85c11756b17a    15637   Safa Al Firas   \N      \N      Colt    \N      Grey    Arabian 2026-03-01      \N      active
e32704a3-a4a1-4d54-963c-8c777a4ea7cb    \N      Ghayyath        \N      107IQ08 Stallion        \N      Bay     Selle Francaise 2016-04-30      \N      active
3f2b4133-ae62-42e6-91ff-e7d2c4455ef5    628     Magic   \N      \N      \N      \N      \N      \N      \N      \N      active
3193395a-d8a5-453c-ab8f-3674d4c5b4b8    15237   Etoile de la Roche      Etoile de la Roche      \N      Mare    \N      Chestnut        SF      2014-07-20      \N      active
e49738e9-8f0a-4226-90ee-161f2896cc6a    7037    Que Pasa (Chocco)       Que Pasa        \N      Gelding \N      Bay     Hannoverian     2017-10-04      \N      active
e67173c3-b0a7-47c9-a703-b82fe0d6d0d6    36      Kabir Ahmar (R.S.)      Kabir Ahmar (R.S.)      \N      Gelding \N      Chestnut        \N      \N      \N      active
6f1e3154-14a1-46a8-9faf-ee69b96a2371    12337   Celo Z  Celo Z  \N      \N      \N      \N      \N      \N      \N      active
8d77b2ca-3a06-4397-b4f1-82940b0cd471    80      Ajial   Ajial   105AU56 Mare    \N      Brown   Holsteiner      2010-01-01      \N      active
1abc3ea0-a055-45d2-9fd9-ff3da182e5f5    98      Al Warid        Al Warid        UAE*6280        Gelding \N      Chestnut        P. Arabian      2005-01-01      \N      active
26b53768-699e-4fe0-bb45-e0cea76461d4    4       Arabelle        Arabelle De See 105LA97 Mare    \N      Bay     Anglo-Arab      2010-01-01      \N      active
49800c23-738d-4282-8a44-d1a4ccf11e63    5       Artvig  Artvig  250001 10713729R        Mare    \N      Isabelle        Fjord   2010-01-01      \N      active
57e9d488-fa06-49ff-a829-565080196562    6       Athos   Athos D'Ober    250001 10352188W        Gelding \N      Isabelle        Fjord   2010-01-01      \N      active
bc785f1a-5963-4c21-9d34-b7fbc01674b1    10      Hazelnut        Ballyroe Grey Hazelnut  372414003099468 Gelding \N      Grey    Irish Pony      2003-01-01      \N      active
1cfae32a-2431-4b86-8e1d-0aa13b0b7578    11      Balou   Balou   103KS57 Gelding \N      Chestnut        Oldenburger     2003-01-01      \N      active
1f9ba834-2060-4c64-b3c4-e85d2d90c8af    82      Caloubet        Caloubet        104NW00 Gelding \N      Bay     OS      2007-01-01      \N      active
8b29306d-783b-41ea-b521-7e671b855687    88      Charly Braun    Charly Braun    105JJ51 Gelding \N      Chestnut        Mecklenburger   2009-01-01      \N      active
572fe76d-fddd-4422-ac7d-328182d752af    86      Cayman 59       Cayman 59       107JM39 Gelding \N      Brown   Holsteiner      2015-01-01      \N      active
34e07531-488e-4e26-bf46-b156f5c92376    84      Carodaz Z       Carodaz Z       102RY23 Mare    \N      Bay     Zangersheide    2004-01-01      \N      active
3388f460-d815-48fc-a427-1289adc0ea2f    830     ONE LEWIS       ONE LEWIS       \N      \N      \N      \N      \N      2012-01-01      \N      active
666f76e1-0fe1-44ca-86e5-d2d79f2058aa    85      Cassiana        Cassiana        105AI37 Mare    \N      Bay     Holsteiner      2008-01-01      \N      active
694a552b-db84-4e21-88d2-218c6de7fb4f    15      Rose    Castle Ellis Rose       372140316869144 Mare    \N      Grey    Irish Pony      2019-01-01      \N      active
ab2fc725-da06-46e6-8b5c-6f900d7c4e8a    87      Cesano NT       Cesano NT       107JU40 Stallion        \N      Grey    Holsteiner      2013-01-01      \N      active
05094d8f-70e5-4baf-bf3d-f152d0cb0193    83      Capture Capture 107IQ56 Gelding \N      BROWN   Holsteiner      2012-01-01      \N      active
05bf209f-ac57-4075-b11c-b31cb8da1503    203     Chelsey Chelsey DE 441410048908 Mare    \N      Bay     Westfale        2008-01-01      \N      active
0e711139-3a00-4a45-b7fb-53b8c53679ba    17      Chilly Pepper   Chilly Pepper 5 104EP48 Gelding \N      Grey    Holsteiner      2007-01-01      \N      active
d1bd0d41-d836-4819-a121-067d370a6365    89      Cortina Cortina 107ZL61 Mare    \N      Brown   Hannover        2017-01-01      \N      active
8df73a20-0b00-4222-8a62-53ce516a7201    19      Codex Two       Codex Two       102UM71 Gelding \N      Dark Bay        Hannover        2003-01-01      \N      active
d4b37e9c-0081-454f-a718-af4cdb007f81    20      Pixie   Dirreen Pixie   372414020248102 Mare    \N      Grey    Irish Pony      2011-01-01      \N      active
dd16f58a-048d-4e3c-9d49-8e5fe253136a    90      Doolin  Doolin Bay Old  106OE57 Gelding \N      Dark chestnut   oldenburger     2014-01-01      \N      active
707d8ed3-9b2d-4e0c-b5bd-4f03174f49ad    22      Douar   Douar Milin Avel        103RZ15 Gelding \N      Grey    Arab    2006-01-01      \N      active
f378c4d0-9cd6-4507-a22e-3327f67cb27d    23      Dukan   Dukan by Nayr ER        105LA95 Gelding \N      Grey    P. Arabian      2010-01-01      \N      active
e194f17a-8924-4f6a-8a05-96a152a43a74    25      Equidia Equidia \N      Mare    \N      Bay     Cross Bred      2007-01-01      \N      active
fc513ffa-ebf2-4e26-b9ab-c0449ac1dccc    27      Ghania  Ghania  UAE* 5715       Mare    \N      Bay     Arab    2004-01-01      \N      active
b888a087-a089-44d8-ad06-4cf1f2215337    91      Glycine Glycine Du Paradiso     107NF59 Mare    \N      bay     Selle Francais  2016-01-01      \N      active
2416c8c8-cd59-471f-a486-907f2f6e6fd3    92      Grazie  Grazie 101      107NC58 Mare    \N      Brown   Holsteiner      2014-01-01      \N      active
b21d3c3e-0f48-4d89-ae09-3479eab4ade8    29      Utika   Godasil Utika   250001 08107265E        Mare    \N      Chestnut        Arab    2008-01-01      \N      active
c04bd1f3-aeff-4914-be91-46d11076568c    202     Guantanamo      Guantanamo Van De Kalevallei    106HJ30 Mare    \N      Bay     SF      2012-01-01      \N      active
f73bc29c-b715-4968-b437-51302ec39fab    31      Hassle  Hassle  95 487 561 X    Gelding \N      Grey    French Pony     1995-01-01      \N      active
a910888e-eb39-491e-95e4-5a1a338efe4f    32      Herby   Hawkfield Herby 372414002814392997      Gelding \N      Grey    Irish   1997-01-01      \N      active
c16c4cbd-3c0e-4129-97e2-a14cccb86bd0    33      Iceford Boy     Iceford Boy     9570727 Gelding \N      Grey    Irish   1995-01-01      \N      active
94b162e6-a9ac-45ae-8411-7c430256474b    93      Irioso W        Irioso W        106HB33 Gelding \N      bay     Hannover        2013-01-01      \N      active
d1a9475d-30f2-4565-b9cc-cb47486d4370    127     Jaifar  Jaifar  UAE* 5363       Gelding \N      Chestnut        P.Arabian       2003-01-01      \N      active
04edebe1-cf3c-4e57-8d06-74fbfc443930    94      Jafa    Jafa    106CD18 Mare    \N      Brown   Oldenburger     2011-01-01      \N      active
b0ec4749-710c-48fb-9016-6db48202040f    35      Joyeuse Joyeuse De La Marre     97 005 697 Z    Mare    \N      Bay     French Pony     1997-01-01      \N      active
e73a0e9a-1518-435b-92f4-81c6d1a2570e    38      K- Jack Killanraher Jack        372414003095572 Gelding \N      Palamino        Irish Pony      2003-01-01      \N      active
e38c9510-b163-4946-9c70-cbc41e33d2cc    39      Bakony  Koheilan Bakony P       105LA92 Gelding \N      Grey    Shagya Arab     2009-01-01      \N      active
6aaf4500-ea31-4dd6-beda-63f91e2c1712    40      Zalka   Koheilan XIII-51 Zalka P        105LF68 Gelding \N      Chestnut        Shagya Arab     2007-01-01      \N      active
2ff25291-c7b6-4e4b-91c2-d4244b1123fb    43      La Roma La Roma 006     UAE40143        Mare    \N      Bay     Westfale        1998-01-01      \N      active
683d28c5-09ce-4886-adaf-c2378c3ad86b    95      Le Clumsy       Le Clumsy       104MA52 Gelding \N      Chestnut        Oldenburger     2007-01-01      \N      active
512ab1bc-a848-429a-9087-17d7078681a0    46      Luna    Luna    250001 52410241W        Mare    \N      Bay     French Pony     2000-01-01      \N      active
2a12df79-2327-4240-8140-63b6eeb3b1c8    133     Maxima  Maxima  UAENF0651       Mare    \N      Bay     Cross Bred      2005-01-01      \N      active
88f847b6-caaa-4736-bee8-13ff4caf88b7    49      Mini    Mini    UAENF06496      Mare    \N      Chestnut        Shetland        1995-01-01      \N      active
ab89b82b-0bbb-4ae4-91c5-c942f5e53bbc    96      Minochio        Minochio        107JW45 Gelding \N      Chestnut        Westfale        2013-01-01      \N      active
9dc9c619-b7c4-4395-9920-9bebe2adf29d    53      Neptune Neptune 250001 52269070S        Mare    \N      Skewbald        French Pony     2001-01-01      \N      active
97b4bf68-b6e5-4942-8b6e-5f416a726302    56      Ouchy   Ouchy   104OC29 Mare    \N      Bay     Cross Bred      2011-01-01      \N      active
08568f63-6a52-4dc7-9553-8882ea1729ee    57      Jim     Peata's Boy     372004000112298 Gelding \N      Bay     Connemara pony  2020-01-01      \N      active
60ac0380-e9e3-44d7-b358-1886264a2b00    59      Pop Corn        Pop Corn        UAENF06498      Gelding \N      Skewbald        Irish   1995-01-01      \N      active
5ab71d0a-d790-4b4b-af08-ce24ad7773f7    69      Glen    Scalp Mountain Boy      372004000108492 Gelding \N      dun     Connemara pony  2020-01-01      \N      active
275c4ae5-fd82-412d-a07d-334e94f6a46d    65      Sahm (R.S)      Sahm (R.S)      UAE* 4846       Gelding \N      Chestnut        P. Arabian      2003-01-01      \N      active
e0835fce-47bd-4f05-8742-539a39282951    66      Salam Jadid     Salam Jadid     250001 05015282F        Gelding \N      Grey    Arab    2005-01-01      \N      active
ebd1fc51-94d5-4dab-b25a-34e7acf799e1    73      Tinky winky     Tinky winky     UAENF06500      Gelding \N      Bay     Irish   1997-01-01      \N      active
d4f83442-a140-4edb-9ae0-fd48a9785d91    74      Twinkle Bay     Twinkle Bay     372414004467156 Mare    \N      Bay     Irish Pony      1999-01-01      \N      active
ba17ad82-0b0f-4b7c-ab76-ef1a1eb41901    75      Ulane   Ulane De Traclin        250001 08701415T        Gelding \N      Bay     Cross Bred      2008-01-01      \N      active
11d1ecad-f343-4fce-aaf3-60fa983f9b79    77      Young Clinton   Young Clinton   372414003095108 Gelding \N      Grey    Irish Pony      1999-01-01      \N      active
c23f295d-2bee-4c15-9c2f-0ca3e1d9143e    130     Lala Bamba      Lala Bamba      372141404684844 \N      \N      \N      Irish Pony      2004-01-01      \N      active
5c489303-0640-4eab-a8cb-dffdf2200f7a    147     Zenobia Zenobia \N      Mare    \N      \N      \N      2007-01-01      \N      active
17803d95-b55c-4ac0-817c-708b70402f7c    7437    Willow (Drennans Willow)        Drennans Willow 958000010899400 Mare    \N      \N      Irish Pony      2019-01-01      \N      active
7fbdf19a-ea91-4a99-a23b-03a7727dd6d8    129     ETNA DE FAVI    ETNA DE FAVI    \N      Mare    \N      Bay     ChevaldeSelleFrancaise  2014-03-06      \N      active
5d79a957-f397-4a34-a645-03c5334fceb3    134     MIJBIL  MIJBIL  \N      Stallion        \N      \N      Arab    2011-01-01      \N      active
cfcf58ce-a85b-4619-b232-b48c2b99b562    132     MAIYZAH MAIYZAH \N      \N      \N      \N      Arab    1999-01-01      \N      active
19055267-8534-43b8-88ee-a303a114c8de    107     CONCHITA        CONCHITA        \N      \N      \N      \N      West Fale       2013-08-06      \N      active
172f33d7-8431-40fc-84ee-2e35db6094e0    139     QATIA DENFER    QATIA DENFER    \N      Mare    \N      Bay     Luxembourgeois  2013-04-27      \N      active
2a567155-2e2c-4153-9257-4b971c12113c    131     LISSARA S       LISSARA S       \N      Mare    \N      Brown   West Fale       2012-04-12      \N      active
8163b10e-1308-442b-ad73-43dac0f0206b    301     CARRERA CARRERA DU HOULBEC      \N      Mare    \N      Dark Bay        SF      2012-04-23      \N      active
370ada88-9266-4154-ae13-35e8726bc871    310     HIDDE   HIDDE FAN LANSICHT      \N      Gelding \N      Piebald Dutch Warmblood 2007-05-31      \N      active
265dc87b-8136-4af8-bf84-15cce35a2a08    309     HIPOLITO        HIPOLITO        \N      Gelding \N      Bay     PRE     2006-01-01      \N      active
b36676ac-3cf0-4f4e-bc3d-390a4b9872f1    7439    Tip Top (Little Dapper) Little Dapper   372141420101868 Gelding \N      \N      Irish Pony      2019-01-01      \N      active
6bbb13c3-5d69-4fe4-bf1b-c04938c81f5f    21      Dokorino (Dokorino)     Dokorino        DE 431319900311 Gelding \N      Bay     Hannover        2011-01-01      \N      active
c91f1e28-5c64-4612-b74c-ab1f66d4391e    50      Mona (Mona)     Mona    250001 52411405F        Mare    \N      Skewbald        Shetland        2002-01-01      \N      active
85c97dd4-67b6-498f-9de5-fff42a422355    28      Glenamaddy Darcy        Glenamaddy Darcy        372004000112302 Mare    \N      grey    Connemara pony  2020-01-01      \N      active
0a87d9f1-9a42-42e7-8062-52f03d34db3e    308     KYRUSA  KYRUSA  \N      Mare    \N      Brown   KWPN    2015-01-01      \N      active
277654c6-5920-4d72-904b-0bac576bb7c1    313     UPPERCOURT NEGRESCO     UPPERCOURT NEGRESCO     \N      Gelding \N      Brown   Irish Sport Horse       2011-01-01      \N      active
98578b91-c647-4d6b-baba-9bd4f6aa591a    304     GENTIANE        GENTIANE        \N      Mare    \N      Chestnut Brown  French Pony     2016-01-01      \N      active
715001a4-6f81-4557-b7b4-4603c367c922    305     MANDARIN        HABERDASHERY MANDARIN   \N      Gelding \N      Palomino        Welsh   2012-01-01      \N      active
52f2e259-349c-4055-b3de-6bdc4b107345    303     CORNET  DUELUND'S CORNET        \N      Gelding \N      Grey    DWB     2017-01-01      \N      active
fd18ceff-2c9c-4a44-bfd0-a060d249d617    829     MONTY   AFRICAN SULTAN  \N      Gelding \N      Bay     Arabian 2012-04-28      \N      active
b01f993d-3701-4f15-a873-a7c3b8662689    1733    DHALAM  ZEUS    \N      Gelding \N      Dark Bay        Crossbred       2008-01-01      \N      active
9db24d66-dd17-4bc7-b792-28ce08cd0462    1833    CAYENNE RB      CAYENNE RB      \N      Mare    \N      Chestnut        Selle Francais  2012-04-28      \N      active
b3b2064b-9d98-4f00-b9b5-92d551ccc0c4    2234    JACARE  JACARE  \N      Gelding \N      Grey    Lusitano        2014-04-20      \N      active
b612fd91-53b2-48ce-bc9b-d3f8203c60e0    12037   JANGO FETT TROTEVAL     JANGO FETT TROTEVAL     \N      Gelding \N      Bay     Selle Francais  2019-04-28      \N      active
3ebae8af-8b4c-41f4-8dd7-865708466f62    3134    CARLOS  OBICARLOS       \N      Gelding \N      Bay     Belgium Warmblood       2014-01-01      \N      active
9f2b32d6-ea20-4dcd-be1c-08e33d516b43    4834    CASTING DE RUEIRE       CASTING DE RUEIRE       \N      Gelding \N      Chestnut        BWP     2012-01-01      \N      active
4aa7bb18-d21f-421f-b2c0-8cb7ca16ae90    4436    OLKE VD GROES   OLKE VD GROES   \N      Stallion        \N      Black   Friesian        2020-02-05      \N      active
ae00da66-b9fb-4874-93d6-802223ac2c80    4434    LOLITA  QUICK STEP      \N      Mare    \N      Grey    Wurttemberger   2012-05-21      \N      active
cc28fa60-c199-4736-8409-5b950cf6b425    5634    TOTTIE  ON FIRE \N      Gelding \N      Dark Bay        KWPN    2019-07-08      \N      active
2328687c-cb15-44cd-adde-141b6d283ccb    5635    LEXIE   SPECIAL LEXIE SD        \N      Mare    \N      Dark Bay        Belgium Warmblood       2018-03-10      \N      active
7e7bd2a3-b4c7-4d0f-a476-f05d74f5825b    5234    DIAMOND ROUGH DIAMOND   \N      Stallion        \N      Dark Bay        Belgium  Warmblood      2017-03-23      \N      active
28f3fbba-d41a-4c88-ad2e-09983513545e    5334    LINA    LINERALLA       \N      Mare    \N      Bay     Belgium  Warmblood      2011-05-31      \N      active
c3cf1475-cef0-4166-bf49-601a888453cc    6334    ACE     CLASS PRIME TIME        \N      Gelding \N      Chestnut        Irish Sport Horse       2018-06-17      \N      active
7a443e5b-439e-406d-9071-7cb8bad8f55d    79      SANDY   SANDY   \N      Mare    \N      Dun     Irish Sport Horse       2019-06-05      \N      active
52231648-b9d8-4def-baa9-f3e8c627acf4    6937    SENSATION       SENSATION       \N      Mare    \N      Bay     German Sport Horse      2013-07-31      \N      active
b22b322c-6035-4697-9309-c8a279786522    7338    TIA     TIP TOP \N      Mare    \N      Chestnut        Welsh X Arab    2010-03-06      \N      active
9e2813cf-e97b-4a4e-80a9-1352ead28d94    7339    MOLLY   FOURFIELDS DAY BREAK    \N      Mare    \N      Bay     Irish Sport Horse       2016-12-05      \N      active
ea15f29f-4aa5-43a3-9278-52ed34e73eeb    7340    RIVER   SECRET SUN      \N      Gelding \N      Black   Hanoverian      2021-03-05      \N      active
b5b72cf6-6d71-4831-9699-8f71570787cf    8037    ASTROLOGY       DELICADO        \N      Stallion        \N      Black   German Sport Horse      2018-06-22      \N      active
954d068a-4eef-4a26-89c6-46c7eaebd19f    7937    FINN    FORT LAUDERDELE 6       \N      Gelding \N      Dark Bay        Hanoverian      2016-05-16      \N      active
77c11e6d-5270-48e0-a0fc-75e34e6a8e95    14837   KING LEON Z     KING LEON Z     \N      Gelding \N      Liver Chestnut  BWP     2019-04-07      \N      active
36e4db8d-0529-4432-8872-6b34980cd0b4    14937   ETROYMN ETROYMN \N      Gelding \N      Chestnut        SF      2014-06-02      \N      active
d5bd7ece-ce0c-4ed9-accb-41b61a45f9fe    8937    GRETZKY GRETZKY \N      Gelding \N      Brown   Swiedish Warmblood      2019-06-07      \N      active
7777790e-5fa9-431b-a7db-fab89730eb7f    12039   HANNAH  HIGHTANA        \N      Mare    \N      Grey    Holsteiner      2020-02-25      \N      active
579743ae-5195-4dca-9aae-ac0f5e9c999b    12038   AMIGO CONTIGO   REDBULL \N      Mare    \N      Grey    KWPN    2021-06-01      \N      active
44cd7916-a904-4878-a7ed-204b372246aa    14237   IJIN    IJIN ARTALENDUIC        \N      Mare    \N      Bay     Selle Francais  2018-10-06      \N      active
0762095a-5f68-4b59-86f2-766cf9ef2c69    12438   BILLY BLOSSOM   BILLY BLOSSOM   \N      Mare    \N      Bay     Zinedine X Vechta       2014-06-03      \N      active
6fabcf6a-6192-4c2b-bf2d-3fad6b0a0de5    12237   CELTION CELTION \N      \N      \N      \N      KWPN    2007-06-24      \N      active
8da786fe-daae-4d48-8e91-8917843fbff0    12238   CHIANTI'S CHAMPION      CHIANTI'S CHAMPION      \N      \N      \N      \N      West Fale       2008-05-04      \N      active
64f0eedb-b654-46fc-8f3d-4319f622d1a8    12338   CADEAU DE MUZE  CADEAU DE MUZE  \N      \N      \N      \N      SBS     2008-07-11      \N      active
bea61a27-3e66-4b09-93a4-c4a9c71ccde3    12339   CAS HOPE        CAS HOPE        \N      \N      \N      \N      Holsteiner      2012-02-20      \N      active
3b76bd0b-a589-48e3-b4f4-d1edc8d470c3    12239   CLUEDO  CLUEDO  \N      Gelding \N      Bay     Oldenburger     2013-10-05      \N      active
02a7b989-bc96-4212-88ab-9c41124b4c52    8237    HARRY   HARRY   372141420706388 Gelding \N      Black   Connemara       2019-01-01      \N      active
bf5b8d2a-33d2-456b-a51c-70d099e69cf4    123     HOLLY HUNTER    HOLLY HUNTER    \N      \N      \N      \N      \N      \N      \N      active
4d6578b1-c138-485c-b723-09769b46bcfc    311     SAPPHIRE LASS   SAPPHIRE LASS   \N      \N      \N      \N      \N      \N      \N      active
ae794684-5b89-45df-8879-23139afc992c    109     DARGENTO        DARGENTO        \N      \N      \N      \N      \N      \N      \N      active
50961ee6-cf34-40ee-8bdb-d37f55069ab6    101     BALLINACARRA MASTER     BALLINACARRA MASTER     \N      \N      \N      \N      \N      \N      \N      active
fa4ba72a-c067-4cbb-b86a-7e4cf8db638f    15037   CHANEL  DANIQUE VAN DE PUTTEHOF \N      Mare    \N      Palominio       Palominio       2016-03-26      \N      active
1c9d36f7-0f9e-48ad-b6ad-471002e4f78d    158     MUHANNAD AL KHALIDIAH   MUHANNAD AL KHALIDIAH   \N      Stallion        \N      Grey    Arabian 2005-01-01      \N      active
68c49dc9-9880-4115-99a6-c8dbd28b760d    168     DUENDE  DUENDE  \N      \N      \N      \N      \N      \N      \N      active
d3ccaeaa-0818-4e87-86b3-3f4602fc27cc    160     FARADAY FARADAY \N      Gelding \N      Black   Friesian        2009-01-01      \N      active
b189c9c9-5544-489e-a977-0efb23c28182    15737   NICO O  NICO O  \N      Gelding \N      \N      Warmblood       2018-05-31      \N      active
31c8d10a-4c86-4312-b87f-789bb093ae64    15738   QOOLMORE        QOOLMORE        \N      Gelding \N      \N      Oldenburger     2017-05-15      \N      active
169eafb1-86f1-40d5-8fae-095a64208fed    166     ADRIAAN ADRIAAN RS      \N      \N      \N      \N      \N      \N      \N      active
01e81231-bb91-46ef-b8de-4ad8c1c5fe28    \N      LULU    DEIRA   \N      \N      \N      \N      West Fale       2019-07-06      \N      active
70520442-1ef3-4156-94c1-aec49d4bdf79    161     CRACK   Crack favory elfes      \N      Gelding \N      Grey    Lipizzaner      2012-01-01      \N      active
699ff103-7bd0-4866-a818-2a0b3d3ed141    159     LILLY   Millersford Pink Lady   \N      Mare    \N      Chestnut        New Forest Pony 2011-01-01      \N      active
\.


--
-- Data for Name: invoice_validations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoice_validations (id, invoice_id, step, action, user_id, comment, created_at) FROM stdin;
\.


--
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoices (id, netsuite_id, customer_id, invoice_date, total_amount, status, billing_month, so_generated, po_number, netsuite_json, sent_to_netsuite) FROM stdin;
4e96dcba-e4e8-4ccc-8ae4-b43fa3880b95    143054  4939968f-1b46-4d2b-83ed-7c1a29806579    2026-04-28      4700.00 PUSHED_TO_ERP   2026-04 t       2026003007      {\n  "customerId": "1582",\n  "po": "2026003007",\n  "department": "188",\n  "memo": "Monthly Livery Invoice - CUS-00169 Sarah Judith Hudson (Apr 2026)",\n  "tranDate": "30/04/2026",\n  "items": [\n    {\n      "itemId": "2339",\n      "horseId": "7a443e5b-439e-406d-9071-7cb8bad8f55d",\n      "horse": "79",\n      "horseName": "SANDY",\n      "quantity": "1",\n      "rate": 200,\n      "description": "LiverySRV-Horse Clipping-Full Body",\n      "department": "",\n      "class": "",\n      "subclass": "37",\n      "location": ""\n    },\n    {\n      "itemId": "2069",\n      "horseId": "7a443e5b-439e-406d-9071-7cb8bad8f55d",\n      "horse": "79",\n      "horseName": "SANDY",\n      "quantity": "1",\n      "rate": 4500,\n      "description": "LiverySRV-Standard Package. Livery",\n      "department": "188",\n      "class": "39",\n      "subclass": "37",\n      "location": ""\n    }\n  ]\n}     t
bc88bf37-fd3c-43d8-9b39-dee15985a4e4    142627  e2c4ce13-deb5-4561-bdeb-504e3c5f7266    2026-04-28      5150.00 PUSHED_TO_ERP   2026-04 t       2026003005      {"customerId":"4039","po":"2026003005","department":"188","memo":"Monthly Livery Invoice - CUS-01077 Nikki Borg Rutter Giappone (Apr 2026)","tranDate":"29/04/2026","items":[{"itemId":"2069","horseId":"0762095a-5f68-4b59-86f2-766cf9ef2c69","horse":"12438","horseName":"BILLY BLOSSOM","quantity":"1","rate":4500,"description":"LiverySRV-Standard Package. Livery","department":"188","class":"39","subclass":"153","location":""},{"itemId":"2100","horseId":"0762095a-5f68-4b59-86f2-766cf9ef2c69","horse":"12438","horseName":"BILLY BLOSSOM","quantity":"2","rate":150,"description":"FarrierSRV-Reset 1 Steel Shoes","department":"","class":"48","subclass":"153","location":""},{"itemId":"2388","horseId":"0762095a-5f68-4b59-86f2-766cf9ef2c69","horse":"12438","horseName":"BILLY BLOSSOM","quantity":"2","rate":175,"description":"FarrierSRV-Set 1 Steel Shoes","department":"","class":"48","subclass":"153","location":""}]}        t
c0234e40-99f7-4723-b737-357c08de3025    143055  ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2026-04-28      19475.04        PUSHED_TO_ERP   2026-04 t       2026003008      {\n  "customerId": "2942",\n  "po": "2026003008",\n  "department": "188",\n  "memo": "Monthly Livery Invoice - CUS-00721 Marjorie Harvey (Apr 2026)",\n  "tranDate": "30/04/2026",\n  "items": [\n    {\n      "itemId": "2568",\n      "horseId": "cc28fa60-c199-4736-8409-5b950cf6b425",\n      "horse": "5634",\n      "horseName": "TOTTIE",\n      "quantity": "0.035",\n      "rate": 623.9999999999999,\n      "description": "ClinicMAT - Cepesedan 20 ml",\n      "department": "187",\n      "class": "46",\n      "subclass": "137",\n      "location": "405"\n    },\n    {\n      "itemId": "2568",\n      "horseId": "fa4ba72a-c067-4cbb-b86a-7e4cf8db638f",\n      "horse": "15037",\n      "horseName": "CHANEL",\n      "quantity": "0.015",\n      "rate": 624,\n      "description": "ClinicMAT - Cepesedan 20 ml",\n      "department": "187",\n      "class": "46",\n      "subclass": "140",\n      "location": "405"\n    },\n    {\n      "itemId": "2568",\n      "horseId": "2328687c-cb15-44cd-adde-141b6d283ccb",\n      "horse": "5635",\n      "horseName": "LEXIE",\n      "quantity": "0.035",\n      "rate": 623.9999999999999,\n      "description": "ClinicMAT - Cepesedan 20 ml",\n      "department": "187",\n      "class": "46",\n      "subclass": "186",\n      "location": "405"\n    },\n    {\n      "itemId": "2070",\n      "horseId": "cc28fa60-c199-4736-8409-5b950cf6b425",\n      "horse": "5634",\n      "horseName": "TOTTIE",\n      "quantity": "1",\n      "rate": 5999,\n      "description": "LiverySRV-Premium Package.. Livery",\n      "department": "188",\n      "class": "39",\n      "subclass": "137",\n      "location": ""\n    },\n    {\n      "itemId": "2070",\n      "horseId": "fa4ba72a-c067-4cbb-b86a-7e4cf8db638f",\n      "horse": "15037",\n      "horseName": "CHANEL",\n      "quantity": "1",\n      "rate": 5999,\n      "description": "LiverySRV-Premium Package.. Livery",\n      "department": "188",\n      "class": "39",\n      "subclass": "140",\n      "location": ""\n    },\n    {\n      "itemId": "2070",\n      "horseId": "2328687c-cb15-44cd-adde-141b6d283ccb",\n      "horse": "5635",\n      "horseName": "LEXIE",\n      "quantity": "1",\n      "rate": 5999,\n      "description": "LiverySRV-Premium Package.. Livery",\n      "department": "188",\n      "class": "39",\n      "subclass": "186",\n      "location": ""\n    },\n    {\n      "itemId": "1740",\n      "horseId": "fa4ba72a-c067-4cbb-b86a-7e4cf8db638f",\n      "horse": "15037",\n      "horseName": "CHANEL",\n      "quantity": "1",\n      "rate": 175,\n      "description": "ClinicSRV -Sedation Fee",\n      "department": "187",\n      "class": "45",\n      "subclass": "140",\n      "location": ""\n    },\n    {\n      "itemId": "1729",\n      "horseId": "fa4ba72a-c067-4cbb-b86a-7e4cf8db638f",\n      "horse": "15037",\n      "horseName": "CHANEL",\n      "quantity": "1",\n      "rate": 300,\n      "description": "ClinicSRV -Dental Rasp - Routine",\n      "department": "187",\n      "class": "45",\n      "subclass": "140",\n      "location": ""\n    },\n    {\n      "itemId": "1740",\n      "horseId": "cc28fa60-c199-4736-8409-5b950cf6b425",\n      "horse": "5634",\n      "horseName": "TOTTIE",\n      "quantity": "1",\n      "rate": 175,\n      "description": "ClinicSRV -Sedation Fee",\n      "department": "187",\n      "class": "45",\n      "subclass": "137",\n      "location": ""\n    },\n    {\n      "itemId": "1729",\n      "horseId": "2328687c-cb15-44cd-adde-141b6d283ccb",\n      "horse": "5635",\n      "horseName": "LEXIE",\n      "quantity": "1",\n      "rate": 300,\n      "description": "ClinicSRV -Dental Rasp - Routine",\n      "department": "187",\n      "class": "45",\n      "subclass": "186",\n      "location": ""\n    },\n    {\n      "itemId": "1729",\n      "horseId": "cc28fa60-c199-4736-8409-5b950cf6b425",\n      "horse": "5634",\n      "horseName": "TOTTIE",\n      "quantity": "1",\n      "rate": 300,\n      "description": "ClinicSRV -Dental Rasp - Routine",\n      "department": "187",\n      "class": "45",\n      "subclass": "137",\n      "location": ""\n    },\n    {\n      "itemId": "1740",\n      "horseId": "2328687c-cb15-44cd-adde-141b6d283ccb",\n      "horse": "5635",\n      "horseName": "LEXIE",\n      "quantity": "1",\n      "rate": 175,\n      "description": "ClinicSRV -Sedation Fee",\n      "department": "187",\n      "class": "45",\n      "subclass": "186",\n      "location": ""\n    }\n  ]\n} t
3d6f4e07-87d3-46b2-b058-18e5f001fb22    145231  3fe1302f-fad6-42cd-915e-acef194e13c6    2026-05-02      2400.00 PUSHED_TO_ERP   2026-05 t       2026003012      {"customerId":"4097","po":"2026003012","department":"188","memo":"Monthly Livery Invoice - CUS-01108 Shaikha Latifah Ahmed Almaktoum (May 2026)","tranDate":"31/05/2026","items":[{"itemId":"2715","horseId":"94f4a18b-0024-488d-9dc6-487620feb8a6","horse":"","horseName":"Cornet XL","quantity":"4","rate":150,"description":"EquestrianSRV-Temporary stables","department":"","class":"","subclass":"","location":""},{"itemId":"2715","horseId":"e32704a3-a4a1-4d54-963c-8c777a4ea7cb","horse":"","horseName":"Ghayyath","quantity":"4","rate":150,"description":"EquestrianSRV-Temporary stables","department":"","class":"","subclass":"","location":""},{"itemId":"2715","horseId":"e97f808a-6c4d-4637-92fc-6692db6b8c01","horse":"","horseName":"Kasseb","quantity":"4","rate":150,"description":"EquestrianSRV-Temporary stables","department":"","class":"","subclass":"","location":""},{"itemId":"2715","horseId":"932f95d6-5ae2-4b41-a034-3b0e99285a22","horse":"","horseName":"Infinity Wow","quantity":"4","rate":150,"description":"EquestrianSRV-Temporary stables","department":"","class":"","subclass":"","location":""}]}  t
a1c6fcc8-f688-4575-b089-780f1e174c58    143057  96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04-28      20000.00        PUSHED_TO_ERP   2026-04 t       2026003009      {"customerId":"366","po":"2026003009","department":"188","memo":"Monthly Livery Invoice - CUS-00034 YOSH HOSPITALITY LLC (Apr 2026)","tranDate":"30/04/2026","items":[{"itemId":"2069","horseId":"217838db-92a3-4f51-b25a-ee20901329ec","horse":"167","horseName":"Kromar Al Sheea / Jawara","quantity":"1","rate":2500,"description":"LiverySRV-Standard Package. Livery","department":"188","class":"39","subclass":"182","location":""},{"itemId":"2069","horseId":"d3ccaeaa-0818-4e87-86b3-3f4602fc27cc","horse":"160","horseName":"FARADAY","quantity":"1","rate":2500,"description":"LiverySRV-Standard Package. Livery","department":"188","class":"39","subclass":"178","location":""},{"itemId":"2069","horseId":"699ff103-7bd0-4866-a818-2a0b3d3ed141","horse":"159","horseName":"LILLY","quantity":"1","rate":2500,"description":"LiverySRV-Standard Package. Livery","department":"188","class":"39","subclass":"180","location":""},{"itemId":"2069","horseId":"1c9d36f7-0f9e-48ad-b6ad-471002e4f78d","horse":"158","horseName":"MUHANNAD AL KHALIDIAH","quantity":"1","rate":2500,"description":"LiverySRV-Standard Package. Livery","department":"188","class":"39","subclass":"184","location":""},{"itemId":"2069","horseId":"cf937986-711a-402c-87e1-66c76e50576d","horse":"170","horseName":"Day Dream Believer / Harry","quantity":"1","rate":2500,"description":"LiverySRV-Standard Package. Livery","department":"188","class":"39","subclass":"179","location":""},{"itemId":"2069","horseId":"70520442-1ef3-4156-94c1-aec49d4bdf79","horse":"161","horseName":"CRACK","quantity":"1","rate":2500,"description":"LiverySRV-Standard Package. Livery","department":"188","class":"39","subclass":"177","location":""},{"itemId":"2069","horseId":"68c49dc9-9880-4115-99a6-c8dbd28b760d","horse":"168","horseName":"DUENDE","quantity":"1","rate":2500,"description":"LiverySRV-Standard Package. Livery","department":"188","class":"39","subclass":"181","location":""},{"itemId":"2069","horseId":"169eafb1-86f1-40d5-8fae-095a64208fed","horse":"166","horseName":"ADRIAAN","quantity":"1","rate":2500,"description":"LiverySRV-Standard Package. Livery","department":"188","class":"39","subclass":"183","location":""}]}    t
3c31925a-5ef1-49c9-8aff-e7cf67cb19c0    142418  53188f5a-025a-4154-b876-5e4ae1f220ed    2026-04-28      10025.00        PUSHED_TO_ERP   2026-04 t       2026003006      {\n  "customerId": "1447",\n  "po": "2026003006",\n  "department": "188",\n  "memo": "Monthly Livery Invoice - CUS-00062 Michelle Schaffers (Apr 2026)",\n  "tranDate": "29/04/2026",\n  "items": [\n    {\n      "itemId": "2285",\n      "horseId": "370ada88-9266-4154-ae13-35e8726bc871",\n      "horse": "310",\n      "horseName": "HIDDE",\n      "quantity": "1",\n      "rate": 425,\n      "description": "FarrierSRV-Reset Shoes Fronts + Trim Hinds",\n      "department": "",\n      "class": "48",\n      "subclass": "53",\n      "location": ""\n    },\n    {\n      "itemId": "2350",\n      "horseId": "370ada88-9266-4154-ae13-35e8726bc871",\n      "horse": "310",\n      "horseName": "HIDDE",\n      "quantity": "2",\n      "rate": 150,\n      "description": "Silicone / Impression Material (Per Hoof)",\n      "department": "",\n      "class": "48",\n      "subclass": "53",\n      "location": ""\n    },\n    {\n      "itemId": "2069",\n      "horseId": "265dc87b-8136-4af8-bf84-15cce35a2a08",\n      "horse": "309",\n      "horseName": "HIPOLITO",\n      "quantity": "1",\n      "rate": 4500,\n      "description": "LiverySRV-Standard Package. Livery",\n      "department": "188",\n      "class": "39",\n      "subclass": "51",\n      "location": ""\n    },\n    {\n      "itemId": "2069",\n      "horseId": "370ada88-9266-4154-ae13-35e8726bc871",\n      "horse": "310",\n      "horseName": "HIDDE",\n      "quantity": "1",\n      "rate": 4500,\n      "description": "LiverySRV-Standard Package. Livery",\n      "department": "188",\n      "class": "39",\n      "subclass": "53",\n      "location": ""\n    },\n    {\n      "itemId": "2099",\n      "horseId": "265dc87b-8136-4af8-bf84-15cce35a2a08",\n      "horse": "309",\n      "horseName": "HIPOLITO",\n      "quantity": "1",\n      "rate": 300,\n      "description": "FarrierSRV-Hoof Trimming for 4 Hooves",\n      "department": "",\n      "class": "48",\n      "subclass": "51",\n      "location": ""\n    }\n  ]\n}  t
e4fe6c59-2ffd-4a66-8149-4eb0bd348ad1    143056  af441b86-4b9a-4810-9cdd-7af4f886aef6    2026-04-28      9769.96 PUSHED_TO_ERP   2026-04 t       2026003010      {\n  "customerId": "4184",\n  "po": "2026003010",\n  "department": "188",\n  "memo": "Monthly Livery Invoice - CUS-01158 Sumaya Salem Aloraifi (Apr 2026)",\n  "tranDate": "30/04/2026",\n  "items": [\n    {\n      "itemId": "1812",\n      "horseId": "31cae8e6-e114-4aad-9715-895c850f1ee0",\n      "horse": "2859",\n      "horseName": "Valentino",\n      "quantity": "1",\n      "rate": 360,\n      "description": "ClinicSRV -External Lab Fee - Strangles ELISA",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "1808",\n      "horseId": "31cae8e6-e114-4aad-9715-895c850f1ee0",\n      "horse": "2859",\n      "horseName": "Valentino",\n      "quantity": "1",\n      "rate": 1250,\n      "description": "ClinicSRV -Pre-Purchase Exam - 5 Stage",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "1808",\n      "horseId": "c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0",\n      "horse": "14139",\n      "horseName": "JUPITER II",\n      "quantity": "1",\n      "rate": 1250,\n      "description": "ClinicSRV -Pre-Purchase Exam - 5 Stage",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "1812",\n      "horseId": "c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0",\n      "horse": "14139",\n      "horseName": "JUPITER II",\n      "quantity": "1",\n      "rate": 360,\n      "description": "ClinicSRV -External Lab Fee - Strangles ELISA",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "1811",\n      "horseId": "31cae8e6-e114-4aad-9715-895c850f1ee0",\n      "horse": "2859",\n      "horseName": "Valentino",\n      "quantity": "1",\n      "rate": 2500,\n      "description": "ClinicSRV -PPE Xray Package 3: Front Feet, Hocks, Fetlocks, Stifles, DSPs",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "1724",\n      "horseId": "31cae8e6-e114-4aad-9715-895c850f1ee0",\n      "horse": "2859",\n      "horseName": "Valentino",\n      "quantity": "1",\n      "rate": 100,\n      "description": "ClinicSRV -Lab - Sample Collection",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "1724",\n      "horseId": "c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0",\n      "horse": "14139",\n      "horseName": "JUPITER II",\n      "quantity": "1",\n      "rate": 100,\n      "description": "ClinicSRV -Lab - Sample Collection",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "2831",\n      "horseId": "31cae8e6-e114-4aad-9715-895c850f1ee0",\n      "horse": "2859",\n      "horseName": "Valentino",\n      "quantity": "1",\n      "rate": 600,\n      "description": "ClinicSRV -Visit Fee Extended",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "2568",\n      "horseId": "31cae8e6-e114-4aad-9715-895c850f1ee0",\n      "horse": "2859",\n      "horseName": "Valentino",\n      "quantity": "0.04",\n      "rate": 624,\n      "description": "ClinicMAT - Cepesedan 20 ml",\n      "department": "187",\n      "class": "46",\n      "subclass": "",\n      "location": "405"\n    },\n    {\n      "itemId": "1801",\n      "horseId": "31cae8e6-e114-4aad-9715-895c850f1ee0",\n      "horse": "2859",\n      "horseName": "Valentino",\n      "quantity": "0.5",\n      "rate": 350,\n      "description": "ClinicSRV -Lab Sample Transport Fee",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "1811",\n      "horseId": "c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0",\n      "horse": "14139",\n      "horseName": "JUPITER II",\n      "quantity": "1",\n      "rate": 2500,\n      "description": "ClinicSRV -PPE Xray Package 3: Front Feet, Hocks, Fetlocks, Stifles, DSPs",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "1801",\n      "horseId": "c6bd0636-6e3d-4cea-b8ea-16bb67c05ee0",\n      "horse": "14139",\n      "horseName": "JUPITER II",\n      "quantity": "0.5",\n      "rate": 350,\n      "description": "ClinicSRV -Lab Sample Transport Fee",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "1740",\n      "horseId": "31cae8e6-e114-4aad-9715-895c850f1ee0",\n      "horse": "2859",\n      "horseName": "Valentino",\n      "quantity": "1",\n      "rate": 175,\n      "description": "ClinicSRV -Sedation Fee",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    },\n    {\n      "itemId": "1769",\n      "horseId": "31cae8e6-e114-4aad-9715-895c850f1ee0",\n      "horse": "2859",\n      "horseName": "Valentino",\n      "quantity": "1",\n      "rate": 200,\n      "description": "ClinicSRV -Ultrasound Exam (Brief)",\n      "department": "187",\n      "class": "45",\n      "subclass": "",\n      "location": ""\n    }\n  ]\n}        t
7e1ceb04-00bd-4d52-b0f6-668d6eac094f    145230  c0471f15-cf19-4ac7-87da-2931db694ddd    2026-05-04      450.00  PUSHED_TO_ERP   2026-05 t       2026003011      {"customerId":"4122","po":"2026003011","department":"188","memo":"Monthly Livery Invoice - CUS-01126 Anastasiia Yershova (May 2026)","tranDate":"31/05/2026","items":[{"itemId":"2715","horseId":"55add96b-8f46-4cd4-905b-cb3613d4b244","horse":"","horseName":"Power Presley","quantity":"2","rate":150,"description":"EquestrianSRV-Temporary stables","department":"","class":"","subclass":"","location":""},{"itemId":"2715","horseId":"55add96b-8f46-4cd4-905b-cb3613d4b244","horse":"","horseName":"Power Presley","quantity":"1","rate":150,"description":"EquestrianSRV-Temporary stables","department":"","class":"","subclass":"","location":""}]}   t
\.


--
-- Data for Name: item_prices; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.item_prices (id, item_id, price, is_active, created_at, created_by) FROM stdin;
aa216d81-4dee-4281-a4f2-3b14645023e5    834900c6-97ec-4aa8-a3b9-eee40c4eca15    200     t       2026-04-06 10:58:04.279529      admin
390b0ebe-0c6f-42c8-bd06-6ee9e36775ff    f988eb97-f452-4c9a-bc84-bf71cd195ff3    1250    t       2026-04-06 11:17:06.408726      orla.ohanlon@adec.ae
638a9c07-872c-45ca-9b4d-87b43429dc73    6b109571-1a7b-4d1f-a9a5-fb85fb82e39b    2500    t       2026-04-06 11:19:03.05768       orla.ohanlon@adec.ae
0777bd75-cf4a-4695-b0de-a0d1cb68f5e8    e6149f99-35ea-483c-a8a0-01dc1128ffc1    100     t       2026-04-06 11:20:05.796547      orla.ohanlon@adec.ae
20bd97a2-bcd6-4047-887b-8447937577e9    31a91729-398b-4c5c-81b1-89daf72b7fc5    624     t       2026-04-14 09:52:07.944954      orla.ohanlon@adec.ae
9aab6dc3-293d-4b9d-a292-5053a05b2da9    cde77c22-7efb-47f5-a23f-62c5e1e32016    175     t       2026-04-14 11:21:05.668614      orla.ohanlon@adec.ae
1dcc57f4-d120-47b2-835c-39a56af9452f    8bdc7827-15b9-4b15-b341-08598255ab11    1051    t       2026-04-16 07:01:19.027235      nixon.silveira@adec.ae
e9abc880-3b55-4b8e-8883-fad1bebf1aa7    edc7d7ae-4e8b-4a37-8aa4-00bee9186849    200     t       2026-04-26 10:42:57.997379      orla.ohanlon@adec.ae
4043a33a-4ed4-41ef-95be-07975b948574    67bd15c4-8a78-47ee-84ac-4caffc4e0dbb    315     t       2026-04-27 13:39:26.403357      orla.ohanlon@adec.ae
b144d916-cb19-491f-8cee-5dcabb599b82    3d1a7667-7ce9-4b29-aff4-bc6b5d2010c1    800     t       2026-04-27 13:45:06.699306      orla.ohanlon@adec.ae
a858bf01-cc2c-48b1-a259-8a2b1c68e7c4    252bd6ae-6987-4108-8414-d014709cc641    150     f       2026-05-01 13:39:04.053502      orla.ohanlon@adec.ae
e2e262f0-5678-4745-ad9f-1ddbee4013ce    252bd6ae-6987-4108-8414-d014709cc641    150     t       2026-05-01 13:39:14.429624      orla.ohanlon@adec.ae
6d47ba3e-240d-4472-8a05-2774956edbdf    28ce5e3e-5d76-48c7-ab47-23b36a469f86    300     f       2026-05-01 13:39:36.280332      orla.ohanlon@adec.ae
ba1f6410-c00f-4791-9905-21902065dc80    28ce5e3e-5d76-48c7-ab47-23b36a469f86    150     f       2026-05-01 13:39:56.155161      orla.ohanlon@adec.ae
38295f47-67c5-4841-9095-ec028c483534    28ce5e3e-5d76-48c7-ab47-23b36a469f86    300     t       2026-05-01 13:40:05.289119      orla.ohanlon@adec.ae
2bd8cc60-ce52-496e-949d-7c77f1a511d7    952061b6-9688-4585-96a6-e69b69db106d    500     f       2026-05-01 13:44:10.151884      orla.ohanlon@adec.ae
4b9d16ae-e3cd-4483-a8cb-e98c200f6e9f    952061b6-9688-4585-96a6-e69b69db106d    500     t       2026-05-01 13:44:29.259594      orla.ohanlon@adec.ae
4e64b1f0-69bb-4c34-90c7-af686b1fac00    d9300ff4-7a1b-4d9f-8154-69c28962fe49    130     f       2026-05-01 13:57:13.356988      orla.ohanlon@adec.ae
125a4e47-e688-40c6-9bea-27258e79f6e3    d9300ff4-7a1b-4d9f-8154-69c28962fe49    780     t       2026-05-01 13:57:33.442268      orla.ohanlon@adec.ae
9476dfa3-d023-444e-8357-92716ed2961f    6069d3b6-f009-4c64-9f6b-2b465729df72    340     t       2026-05-02 13:28:07.300172      orla.ohanlon@adec.ae
d910e7b0-173c-4f16-88ff-d1344404d7a7    66765bc5-f937-4071-b6b0-19f979447d20    56      t       2026-05-02 13:31:43.932168      orla.ohanlon@adec.ae
9435e38e-b223-4530-b9bf-e1b3b33c2a3a    dceba4f6-a5bc-4a50-97eb-008121b1489b    300     t       2026-05-02 13:33:03.586438      orla.ohanlon@adec.ae
0ebb0916-409f-415f-87d1-ce5b0514a00a    f1383820-34d0-46c1-af5d-b0368a043731    378     t       2026-05-02 13:33:52.080608      orla.ohanlon@adec.ae
852084f7-e519-471e-b9de-f366c182e486    612e5ad2-02ab-4994-9a3d-b056503c561c    250     t       2026-05-02 13:34:44.361936      orla.ohanlon@adec.ae
04e64291-12fc-48aa-bd4d-dfd2c217f756    cb977323-d2c1-4c9c-864c-f589e8196dc6    500     t       2026-05-02 13:35:34.226473      orla.ohanlon@adec.ae
9af87eef-f6f6-45e5-b35b-1427c45d6d36    1edb2d92-f0d7-428e-8866-951b4dce645f    2500    f       2026-05-02 13:45:23.153873      orla.ohanlon@adec.ae
7595e0eb-d053-419a-8ec6-4a290dce13b2    1edb2d92-f0d7-428e-8866-951b4dce645f    2200    t       2026-05-02 13:45:51.66452       orla.ohanlon@adec.ae
c3df8485-45ba-4a7e-8c24-2868b5777dec    9e2ec26d-2c40-42ca-b10a-aa241f21c6bf    300     t       2026-05-02 13:46:44.039049      orla.ohanlon@adec.ae
089e6ea7-0663-4a1d-84b7-cd35d48ad0c5    4dda5637-1500-46fd-83e0-59f79a3caf95    350     t       2026-05-02 13:47:30.032215      orla.ohanlon@adec.ae
1a8f5891-75a8-4e5e-8f53-15c7b95f50a7    3bba8890-8f31-4721-a1eb-23b1bc82b540    12.50   t       2026-05-02 13:54:28.211686      orla.ohanlon@adec.ae
82cb42b3-dfb7-4fc5-9a75-d3d283e03dea    e6594f6e-5c87-4a9a-8178-02ddc964be1c    100     f       2026-05-04 10:15:18.599302      orla.ohanlon@adec.ae
800a16b7-d900-4504-891b-0837c1d746a2    e6594f6e-5c87-4a9a-8178-02ddc964be1c    90      t       2026-05-04 10:15:26.197705      orla.ohanlon@adec.ae
1899b4ae-252e-48ff-8cab-40063220c230    dc3474e9-1bda-44df-9324-49f155bba5c6    30      t       2026-05-05 10:31:47.642706      orla.ohanlon@adec.ae
9bc6b306-3e70-43a3-ba68-7463cb11e675    5b2c8e4b-f4b2-4c45-aa3c-4f971a2a7b69    180     t       2026-05-05 13:55:00.870867      orla.ohanlon@adec.ae
80c0c353-b3fd-4a1a-818b-aac0c8eb2b76    f1567c9c-be47-4be0-9005-2bbd561bf765    180     t       2026-05-05 13:55:21.536865      orla.ohanlon@adec.ae
46a2d274-ceed-4171-bf3c-1239f9e2d732    2dbbcf5a-acc0-4e55-9d59-180ec55d3745    278     t       2026-05-05 13:57:58.5368        orla.ohanlon@adec.ae
989458ea-2a3a-4961-825b-5d6554dc4af6    b9bb0433-85e7-4e32-b4fe-bc2fbc546754    400     t       2026-05-05 13:59:59.462293      orla.ohanlon@adec.ae
579e9c48-9414-4677-8c5d-be17054724d5    b35649fd-0d77-4ea6-a6e6-3f913448911f    300     t       2026-05-07 08:28:14.145196      orla.ohanlon@adec.ae
97f1eee4-79e2-4fa9-83b7-8c4246e4a253    d09293ab-4fb8-470f-9df3-37087aea5212    350     t       2026-05-07 08:32:04.719521      orla.ohanlon@adec.ae
e9af9a41-3e2a-4513-a910-37a7bbc761a0    57429aed-2879-493d-b541-71347a13266a    150     t       2026-05-07 08:48:42.100253      orla.ohanlon@adec.ae
c7daa275-6b01-438c-a89e-b10856b05c10    db25e6c6-88ec-4341-91dd-1d61e018244b    18      f       2026-05-05 10:26:25.527699      orla.ohanlon@adec.ae
010786a3-8844-42b0-8495-934adab73765    db25e6c6-88ec-4341-91dd-1d61e018244b    24.24   t       2026-05-07 08:55:00.774748      orla.ohanlon@adec.ae
8d938c08-c1d5-43e0-b4e4-08264d7c4d2f    c52845a1-6209-4f20-a232-2e83c2c522ac    600     t       2026-05-08 07:45:56.2054        admin
36937563-c39c-4326-88b8-083014d9d799    05e28e05-df88-4bd8-b38b-5fcad1a689be    200     t       2026-05-08 10:21:07.717528      orla.ohanlon@adec.ae
0d60436f-0686-41a9-9df1-dfd41dd1c2ca    cb849f39-2cb0-4c35-a03c-953402a8132d    400     t       2026-05-08 10:22:42.765014      orla.ohanlon@adec.ae
a842d725-3259-4d48-815d-5a60ae6f7a46    4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    300     t       2026-05-08 11:38:11.334854      orla.ohanlon@adec.ae
2e236976-bf16-4e1f-b96c-520e93dd963c    cc0a7c79-e7b4-4145-a0de-91f9e9e8deca    150     f       2026-05-02 13:30:46.329425      orla.ohanlon@adec.ae
b1e3abbf-9f86-4738-93fb-6e82a2c30239    cc0a7c79-e7b4-4145-a0de-91f9e9e8deca    200     t       2026-05-08 11:42:22.974638      orla.ohanlon@adec.ae
486f3d1e-33f9-44f2-a861-6e0e20cb4ac3    2e06201f-ef06-4cdb-aafe-2a5c8efaa28d    340     t       2026-05-08 13:25:07.023489      orla.ohanlon@adec.ae
2d5e8683-afba-4fb3-80c3-fa3190125b56    07e360bc-92f2-4eac-beb4-0cac5e8b0101    230     f       2026-05-10 13:50:52.442877      orla.ohanlon@adec.ae
26a968ed-1ed8-4cfc-a3dc-c57e1c6603c3    07e360bc-92f2-4eac-beb4-0cac5e8b0101    103.95  t       2026-05-10 13:51:42.505462      orla.ohanlon@adec.ae
bbab5d7b-45e3-4d39-b637-1b135dd72564    dae09228-c921-4b5d-9e6c-87e5a2daea20    450     t       2026-05-10 13:55:30.898938      orla.ohanlon@adec.ae
8a04db16-72b6-419e-acc2-8cc4e9927305    2ff1dc27-1d89-451d-9e33-deda80c3f31c    350     t       2026-05-12 08:25:51.866785      orla.ohanlon@adec.ae
f5f321d1-dd72-4068-89d0-8163058b4f0c    17d4e825-c298-441e-a85c-c5ff6cbd15a4    140     t       2026-05-12 09:52:38.01761       orla.ohanlon@adec.ae
20f38d2a-0f60-4602-8305-ada7ec752b54    96f4a9ae-e972-4dee-bd40-8e8223f2d4c6    300     t       2026-05-17 17:33:38.487664      orla.ohanlon@adec.ae
17cfae5b-118c-41b5-8463-7f437ec5c60a    a46629db-843b-46b3-bd1f-c786a900f21e    300     t       2026-05-19 07:26:55.192009      orla.ohanlon@adec.ae
2f3df10f-79be-421d-8b45-45bee0239d5d    718bbe4d-526c-4be9-a0d8-b25eda4df34f    180     t       2026-05-19 07:28:03.527026      orla.ohanlon@adec.ae
6d0e8685-b52f-47ba-92b8-e322096987e0    6925ceb6-8f53-4e2b-b1f1-76924af14ef9    862.50  t       2026-05-19 07:51:46.65291       orla.ohanlon@adec.ae
cce2ddd5-1177-47e8-86c0-072a671ef073    9a92223c-b130-450c-be27-175b5cd20691    225     t       2026-05-30 04:15:18.758865      orla.ohanlon@adec.ae
ef033f28-4ae7-4d94-88ab-827479007951    58ac3468-68be-4292-a89c-e54113afe127    180     t       2026-05-30 04:21:56.246717      orla.ohanlon@adec.ae
7c951de9-b125-43c2-b66d-eafa8c0442c6    09e5ea1e-bdbd-40c5-bf88-144ac5736c32    354     t       2026-05-30 04:23:21.352434      orla.ohanlon@adec.ae
2c75a8f7-cc55-462b-b178-3333644e0903    71503f5b-25c9-418a-bf39-2c8df2215d2f    69.30   t       2026-05-30 04:25:31.229934      orla.ohanlon@adec.ae
01875b89-e073-430a-8b6a-4c8b2875d3f2    10cb955d-f9ca-4602-a517-9109f89b2dfa    250     t       2026-05-30 04:53:29.146243      orla.ohanlon@adec.ae
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.items (id, netsuite_id, name, price, is_livery_package, unit_factor, average_cost, is_inactive, last_purchase_price) FROM stdin;
fdb7f1d5-449b-4e60-94be-2802d2794e3c    2498    BHS Exams Stage 1 Care Private Exam (1 Person)  1000    f       \N      0       f       0
3fdebb34-f414-48ed-9c28-97398a755823    2873    Betting Coin Technology \N      f       \N      \N      f       0
487f6f08-a716-4d66-b074-6c4566eab9ff    2244    ClinicMAT - Disinfectant Wipes Dispenser        5       f       1       40.5    f       40.5
a6c7e00d-2bc4-44de-a111-18cddc3de556    2210    ClinicMAT - Disposable shoe Cover Plastic blue  60      f       10      10      f       10
a6cdfe2d-1b5b-434d-a3eb-225e1b8c54a1    2102    ClinicMAT - Enalees Respiratory Panel   \N      f       5       1378.255        f       1421.695
3ce4c3be-5596-4e3e-b6b4-b82484aff6ba    453     ClinicMAT - Euthanex 50 ML      513     f       1       380     f       380
528dac31-c786-4467-9f6c-afbd3c907327    2245    ClinicMAT - F10 Hand Pump- for 5 L Bottle.      5       f       1       \N      f       0
3f261316-8c3c-40c0-acd1-c06cd56f97a5    2363    ClinicMAT - Heine Beta A 200LED Ophthalmoscope. 373.35  f       1       3025.31 f       3025.31
a70ed0f3-d921-4863-8e82-6b00b25f0518    2579    ClinicMAT - Intibio A2MG Plus 4ml       373.35  f       1       \N      f       425
e306c7d2-40ec-48ac-998d-dfb438af6a19    2659    ClinicMAT - Kurasyn 360 1 Ltr   5       f       1       260     f       260
cb8fe7f6-4e5a-4da1-9e4c-e91d0027d1a1    2814    BHS Stage 1 Care - Devolved Assessment Private (1 Person)       1325    f       \N      \N      f       0
00b722e0-ccfe-4f93-b9a8-9fc0940c4b5c    2815    BHS Stage 1 Care - Devolved Assessment Semi-Private & Group (2 – 4 People)      1075    f       \N      \N      f       0
c8c44da3-74f9-4fec-8264-e6ba4d16977e    2819    BHS Stage 1 Complete - Devolved Assessment Semi-Private & Group (2 – 4 People)  2150    f       \N      \N      f       0
acd0be4e-576c-47e7-b871-3edb19952bbc    2816    BHS Stage 1 Ride - Devolved Assessment Private (1 Person)       1325    f       \N      \N      f       0
945e0490-adf0-487c-8560-1a1c396df024    2817    BHS Stage 1 Ride - Devolved Assessment Semi-Private & Group (2 – 4 People)      1075    f       \N      \N      f       0
252bd6ae-6987-4108-8414-d014709cc641    435     ClinicMAT -Intralog 3ml (12pce/box)     \N      f       1       64.99857143     f       75
4fdc8758-d496-4fcf-9a76-cc771a702565    2499    BHS Exams Stage 1 Care Semi – Private s Group Exam (2 – 4 People)       750     f       \N      0       t       0
1f8d9c1c-a465-4267-a140-563fbd3b48c5    2502    BHS Exams Stage 1 Complete Private Exam (1 Person)      2000    f       \N      0       t       0
a721b7ca-e985-4f9e-a49c-3f0cd54491b7    2503    BHS Exams Stage 1 Complete Semi – Private s Group Exam (2 – 4 People)   1500    f       \N      0       t       0
dbdbe3ee-c60a-4920-b9bc-203108df9d96    2500    BHS Exams Stage 1 Ride Private Exam (1 Person)  1000    f       \N      0       t       0
dbf43fd2-08bd-4066-a2c3-128f44ced3e1    2501    BHS Exams Stage 1 Ride Semi – Private s Group Exam (2 – 4 People)       750     f       \N      0       t       0
93108370-e538-4465-a89a-339d3897f9e9    2818    BHS Stage 1 Complete - Devolved Assessment Private (1 Person)   2650    f       \N      \N      f       0
521bf092-226e-4833-8e4c-4cf38237f824    2426    BrandingMAT -CLASSY HOODIE L    \N      f       \N      \N      f       125
79eb03ab-fba4-429e-a29a-ce7f8469ec63    2425    BrandingMAT -CLASSY HOODIE M    \N      f       \N      \N      f       0
54f09c86-4f5f-4304-893e-df5966b952b9    2427    BrandingMAT -CLASSY HOODIE XL   \N      f       \N      \N      f       125
d217e37a-3213-473e-b86f-a86dff1e171e    2428    BrandingMAT -CLASSY HOODIE XXL  \N      f       \N      \N      f       125
3d57454d-493f-4101-84f4-8ddd2adca9a3    2447    BrandingMAT -CLASSY TO-DO LIST  \N      f       \N      \N      f       45
fed92819-fb04-47f1-9229-2d8d8e2c2b0c    2430    BrandingMAT -FUNKY HOODIE L     \N      f       \N      \N      f       125
a05cd2ab-2b3c-40fa-99a3-f9b0985be6b8    2429    BrandingMAT -FUNKY HOODIE M     \N      f       \N      \N      f       125
ec5076b3-81c8-47d2-8716-8deacff46e8d    2431    BrandingMAT -FUNKY HOODIE XL    \N      f       \N      \N      f       125
cdeae605-9a32-4a28-b560-03af0e12ca14    2432    BrandingMAT -FUNKY HOODIE XXL   \N      f       \N      \N      f       125
5b778661-4d99-48c7-aa64-743fb1c8f938    2445    BrandingMAT -FUNKY NOTEBOOK     \N      f       \N      \N      f       110
ed94405f-5f91-4879-bd2c-392847aff949    2438    BrandingMAT -FUNKY T-SHIRT L    \N      f       \N      \N      f       70
d38e58c3-24fe-40ee-b13a-afa3ea12c358    2437    BrandingMAT -FUNKY T-SHIRT M    \N      f       \N      \N      f       70
f63f53c1-7583-4937-bee4-21a321bd2a5a    2439    BrandingMAT -FUNKY T-SHIRT XL   \N      f       \N      \N      f       70
7f427c34-d8ba-4867-8b0d-374d90e3dcf8    2440    BrandingMAT -FUNKY T-SHIRT XXL  \N      f       \N      \N      f       70
cf77b2fc-7b42-4b28-b296-c281a3a9d478    2448    BrandingMAT -FUNKY TO-DO LIST   \N      f       \N      \N      f       45
33176ad7-703d-4a20-9a8e-f5b9545d9396    2442    BrandingMAT -FUNKY TOTE BAG     \N      f       \N      \N      f       50
448eb031-13c8-43d1-acb0-84eed83dfa9e    2450    BrandingMAT -GREEN PACK OF 3 STICKERS   \N      f       \N      \N      f       45
1c2a4853-d3e9-4fd5-b87c-2cb6896290a8    2451    BrandingMAT -ORANGE PACK OF 3 STICKERS  \N      f       \N      \N      f       45
b0f603d1-832f-4c9f-8aee-c3398850d3cb    2449    BrandingMAT -PINK PACK OF 3 STICKERS    \N      f       \N      \N      f       45
f94abe2b-4e82-4834-ab0a-c668804b28e9    2422    BrandingMAT -TRENDY HOODIE L    \N      f       \N      \N      f       125
bc530aeb-1d47-4ad9-887d-7de610650a35    2421    BrandingMAT -TRENDY HOODIE M    \N      f       \N      \N      f       125
16aa5217-cfa3-4258-a4f4-4edb1437265c    2423    BrandingMAT -TRENDY HOODIE XL   \N      f       \N      \N      f       125
d876f83e-100e-4bf7-bf48-0b5a980b66bb    2424    BrandingMAT -TRENDY HOODIE XXL  \N      f       \N      \N      f       125
67ee89cb-45b4-4904-86e3-8653949101a2    2443    BrandingMAT -TRENDY NOTEBOOK    \N      f       \N      \N      f       110
628d25a9-4249-4940-96ac-4abf18497451    2434    BrandingMAT -TRENDY T-SHIRT L   \N      f       \N      \N      f       70
b551b5d0-a13a-45b7-9330-0e43c0a1bac8    2433    BrandingMAT -TRENDY T-SHIRT M   \N      f       \N      \N      f       70
9f99f5b2-1574-4f06-a560-bc24478f3440    2435    BrandingMAT -TRENDY T-SHIRT XL  \N      f       \N      \N      f       70
915a9113-2057-4b4d-a787-0d5290420768    2436    BrandingMAT -TRENDY T-SHIRT XXL \N      f       \N      \N      f       70
c883d08e-22ff-4470-a0c0-4717e58091b8    2446    BrandingMAT -TRENDY TO-DO LIST  \N      f       \N      \N      f       45
6a2fdd76-38b9-4586-8974-e54fd1502ffc    2441    BrandingMAT -TRENDY TOTE BAG    \N      f       \N      \N      f       50
b0719874-8698-4a2b-a34a-c73aa764ecf0    2675    Brother Toner TN-2130   \N      f       \N      127     f       127
e6c039a8-112c-4b3e-b0bd-a1ef91b10518    2735    COH – Turnover Rent (Unbilled)  \N      f       \N      \N      f       0
c5a01144-8ad4-44c6-9aba-566c9293a1e4    483     CarpentryMAT -ALUMINUM LOCK PIPE        \N      f       \N      2.5     f       2.5
2dbbcf5a-acc0-4e55-9d59-180ec55d3745    268     ClinicMAT -Mepivicaine (100ml bottle)   \N      f       100     129.07179487    f       139
952061b6-9688-4585-96a6-e69b69db106d    2415    ClinicMAT -Phenylarthrite inj 100 ml    5       f       100     44      f       44
1edb2d92-f0d7-428e-8866-951b4dce645f    2731    ClinicSRV - Alpha 2 Macroglobulin (Kit, blood draw + processing)        300     f       \N      \N      f       0
6069d3b6-f009-4c64-9f6b-2b465729df72    1797    ClinicSRV -Export paperwork + blood sampling    70      f       \N      \N      f       0
f0ebd527-8cf6-4628-bc2d-bb33f9f5243f    2292    ClinicMAT - Melolin Non-Adhesive Dressing  size 10 cm ×10  1×10 pcs/pkt 60      f       10      75      f       75
c52845a1-6209-4f20-a232-2e83c2c522ac    2366    ClinicMAT - Meloxicam Inj 100 ml        373.35  f       100     285     f       285
121c3590-fd81-4064-bdf0-949ced0e3e15    2658    ClinicMAT - Mood Balancer 1ltr  5       f       1       \N      f       180
3b34db42-44bb-45d4-8c81-ee92dee9c0d4    2103    ClinicMAT - Nasopharyngeal Swabs        \N      f       10      40.18387097     f       42.44
60a49429-cc9f-4cc3-98c0-1dcc3f499398    2208    ClinicMAT - Riketron N Injection 100 ml 60      f       1       \N      f       40
17d4e825-c298-441e-a85c-c5ff6cbd15a4    2214    ClinicMAT - Sed Ace Gel 30ml    780     f       1       85      f       85
6af8337e-0259-445c-95a0-cc7a670d7dd2    2369    ClinicMAT - Silvadiazin Cream 50g       373.35  f       1       \N      f       9.5
045013c4-c54d-44da-8d94-3921558a0a58    2216    ClinicMAT - Sucralfate Powder 500g      780     f       1       350.02333333    f       350
39d6af70-1c8a-44d7-b815-cd7964cdd3d8    2129    ClinicMAT - prednisolone 20mg tablets   53      f       1       53      f       53
5e3b5b9f-1cda-4d0d-a8f2-f7060fb26aeb    722     CleanMAT -FURNITURE POLISH      \N      f       \N      9.5     f       30.43
114b06ba-4d6b-446e-880e-a3cf6ec934c9    471     CarpentryMAT -ASSEMBLY HARDWARE \N      f       \N      39.5    f       39.5
3af26772-67ed-42f4-83a3-bbd7e5089d6b    486     CarpentryMAT -BIG SIDE DOOR LOCK        \N      f       \N      25      f       25
0e8cd0da-6f67-4209-9ce1-7df5e219462e    479     CarpentryMAT -CUT FOAM(OLD)     \N      f       \N      3.5     f       3.5
c0de37a5-b3e8-4b13-9db3-f4c32adaa5fb    472     CarpentryMAT -DOOR KNOB \N      f       \N      15      f       15
ae47c473-0d44-4731-b459-af9c01ea8c10    473     CarpentryMAT -DOOR LOCK \N      f       \N      4.5     f       4.5
3cafa866-8f87-47c8-8a6a-e568c0004338    478     CarpentryMAT -FOAM CUSHION      \N      f       \N      37.5    f       70
db3394fa-7f38-429e-b847-75a15bd1a519    474     CarpentryMAT -HANDLE TOOLS      \N      f       \N      1.5     f       1.5
9e795676-6e87-441d-b908-a3945cf669ea    485     CarpentryMAT -METAL HANGING RINGS       \N      f       \N      3.5     f       3.5
f06b0e68-872c-46cc-81f1-79ab033eee2c    481     CarpentryMAT -PRAGATI DOOR SIDE LOCK    \N      f       \N      2       f       2
8a326fd3-da0f-4e54-80f1-8fbedd245135    475     CarpentryMAT -SCALING RULER METAL       \N      f       \N      3.75    f       3.75
612e144d-5f73-4d8b-8c13-28e3fe5a09fa    477     CarpentryMAT -SK KING SAW BLADE ROUND   \N      f       \N      55      f       55
3b99c908-1122-4a53-b2ff-87be62c89a8c    482     CarpentryMAT -SMALL STUD 1X50 PACKET    \N      f       \N      50      f       50
bd204308-d259-47f6-8eeb-aaf636767277    480     CarpentryMAT -STAINLESS HANGER  \N      f       \N      18.5    f       18.5
a8fb236d-9aae-4758-87bd-589d8251a30b    484     CarpentryMAT -TANGIT SPECIAL ADHESSIVE  \N      f       \N      10.5    f       10.5
4f702d0b-d5de-4b26-8e8a-25c2f28a6ace    476     CarpentryMAT -WOODEN SHAVER TOOLS       \N      f       \N      24.5    f       24.5
3b4713ca-a13c-4c50-97d0-b3883b38a986    2850    CleanMAT -AIR FRESHNER Micro Airoma 100 Ml Refill       \N      f       \N      \N      f       9
cee9e86b-b6a4-4ce4-831f-4242029ffd5a    730     CleanMAT -AIR FRESHNER-300ML    \N      f       \N      4.73933333      f       4.739333333333333
7744d4e7-6ab1-4b1e-960a-e34d5861ce42    731     CleanMAT -AIRPORT MOP SET       \N      f       \N      34      f       34
8ae613cf-3793-4ff2-954a-f42311ca9168    720     CleanMAT -ALL PURPOSE CLEANER 5 LTR     \N      f       \N      8.405   f       37
55d1c750-3c8a-4278-9dd2-22610dd34604    2849    CleanMAT -CHEMEX FLUSH CLEAN 5LTR       \N      f       \N      \N      f       14.5
76e31550-ff02-43e5-9c3d-f5858db62e66    753     CleanMAT -CLEANING GLOVES       \N      f       \N      20.1244 f       11
2f99afbc-7a99-47c3-823d-3156876b20f2    733     CleanMAT -CLOREX-GALON 4 LTR.   \N      f       \N      14.87136364     f       16.5
9a076ab3-2ade-46e4-a8a6-fa3f752d7004    764     CleanMAT -DETERGENT POWDER 19 Kg – BRAND: TIDE DEEPIO   \N      f       \N      89      f       89
a8f85f66-4a38-4967-a7a1-b8fc80a18d13    756     CleanMAT -DETTOL 4LTR   \N      f       \N      54.535  f       60
bc7688f0-4bf5-4bbb-962d-0b92d8e41a90    762     CleanMAT -DETTOL DISINFECTANT SPRAY 450ml       \N      f       \N      34.31833333     f       37
4273531f-85a3-4233-8f0d-07c8d0ad4666    759     CleanMAT -DETTOL HAND WASH 1 LTR        \N      f       \N      20.71777778     f       20.71727272727273
b5027e34-6e83-4ca6-b91e-e4a8f091808a    761     CleanMAT -DETTOL HANDSANIZER 400ml      \N      f       \N      26.98   f       26.98
ce84f2f7-11b4-4ed6-a236-a6e064a22918    735     CleanMAT -DUST PAN WITH RUBBER BEADING WITH HAND BRUSH ITALY    \N      f       \N      6       f       6
662e0210-1f2f-464c-bf8d-b3abfeff16f5    736     CleanMAT -DUSTER        \N      f       \N      8       f       8
2188c8ae-1831-4d77-a212-d982dacca106    2466    CleanMAT -Disposable Pool/Bath Towel (80x160cm) x 25    \N      f       \N      75      f       75
427aac95-7b43-4859-91f9-7f1bd9af876c    719     CleanMAT -FAIRY LIQUID  \N      f       \N      11.23076923     f       11.5
03e35a46-c9e0-4561-912f-763ae0f4be29    2128    CleanMAT -FLOOR WIPER 75CM  WITH METAL HANDLE   \N      f       \N      21.85714286     f       22
fbd363a8-39db-4e0a-9632-2ca298931d44    721     CleanMAT -FLOOR WIPER CORONET (GERMANY) WITH METAL HANDLE       \N      f       \N      10.8075 f       8.5
0f512206-c3fb-471f-be39-a049a28043b8    2273    CleanMAT -GARBAGE BAG -BLACK-20KG 110 X 130     \N      f       \N      65.006  f       87
aa504fc2-b19a-4bf4-9bf1-2fae3608b318    2845    CleanMAT -GARBAGE BAG -BLACK-20KG 65 X 85       \N      f       \N      \N      f       87
a9fc93e8-d849-480f-be60-653fb179fe9e    732     CleanMAT -GARBAGE BAG -BLACK-20KG 85X110        \N      f       \N      \N      f       75
9d611ff2-3f0a-4091-9d7b-e6ced87e7db4    2844    CleanMAT -GARBAGE BAG -BLACK-20KG 95X110        \N      f       \N      \N      f       87
a0368ecc-df4d-4bd5-a2bc-157d1838998c    751     CleanMAT -GARBAGE BAG WHITE 50X60 CM.   \N      f       \N      100.8   f       100.8
76c9c2d0-c1c3-4aaa-88bc-08c4945e1662    723     CleanMAT -GARDEN RACK WITH WOODEN HANDLE        \N      f       \N      22      f       22
63328b3e-f94d-46f3-b025-16274b81886c    2467    CleanMAT -Hygiene Wet Towel Scented L (30 x 30 cm) x150 \N      f       \N      \N      f       330
ec4be1e0-f6a0-47da-ad41-8969403efd33    746     CleanMAT -INTERFOLD TOILET TISSUE PAPER 20X150  \N      f       \N      46      f       46
eec6452d-c2d1-4571-9395-b30b1fcc1017    724     CleanMAT -KENTUCKY COTTON MOP ONLY      \N      f       \N      \N      f       22.05
5bd042ea-78ad-444d-8a36-006ab3183d7f    725     CleanMAT -KITCHEN TOWEL \N      f       \N      4       f       4
12843a6f-7700-468f-9fe9-6cc2c81cf1c9    726     CleanMAT -KLEENEX       \N      f       \N      5.1730102       f       5.4
b08e9536-8b69-46d6-8bfc-ba16e2cc7484    728     CleanMAT -LUX HAND WASH-500 ML  \N      f       \N      13.77   f       14
144a1d5f-a75c-4682-88b0-b78c31be388c    2526    CleanMAT -Lice Spray For Helmets        \N      f       \N      93      f       93
6442feb9-42e7-4b9a-b790-811747c4e098    2847    CleanMAT -MAXI ROLL (1000G) CUT20CM(1x6)        \N      f       \N      \N      f       53
90426fc7-8df3-4806-9e6f-8eaa423d8485    2842    CleanMAT -Masafi Boutique Tissue 100 Sheets x 2 Ply     \N      f       \N      \N      f       2.5
b7ca44b6-7cda-4525-9ee9-fe35ddd1d9d8    2362    CleanMAT -Oshibori Face Towel   \N      f       \N      \N      f       6.9
3382b68f-d4c5-4852-8f97-3987fe0d354b    729     CleanMAT -PIF PAF       \N      f       \N      8.8     f       8.5
2404286b-d96f-47a3-ae10-631c0b21d480    2182    CleanMAT -PLASTIC SHOWEL WITH WOODEN HANDLE     \N      f       \N      \N      f       210
6e8bc394-58fa-4e0a-a57e-c4547c120a57    2848    CleanMAT -SANITOL Disinfectant 5LTR     \N      f       \N      \N      f       28.75
6cd3b853-27ab-448c-ae11-d7684865c9d5    737     CleanMAT -SMALL BUCKET  \N      f       \N      6.5     f       6.5
cb735355-da49-47ef-a3d2-c08eb77f2466    738     CleanMAT -SOFT BRUSH WITH HANDLE        \N      f       \N      8.39736842      f       7.5
f6a9c2e8-5f08-439c-a4c4-f0a36b072a82    739     CleanMAT -SPONGES       \N      f       \N      2       f       2
ecad176a-10f0-4069-8cb1-48472a3208c9    760     CleanMAT -STEEL SHOWEL WITH WOODEN HANDLE       \N      f       \N      \N      f       0
2d5bda49-b6e4-4b9d-9a6d-a4c5157392a2    741     CleanMAT -STREET BROOM 12 INCH WITH W-HANDLE    \N      f       \N      11.06285714     f       11.062105263157894
f9798867-2569-4ba2-8106-2556a30c179a    742     CleanMAT -STREET BROOM 24 INCH  \N      f       \N      18.89294118     f       17
47464d9d-a0b9-400b-a003-9e0c65206eff    757     CleanMAT -TIDE – 260gm  \N      f       \N      \N      f       0
31d82eb6-6f83-4db7-9d57-2b6563e2f247    744     CleanMAT -TOILET CLEAN BRUSH    \N      f       \N      6       f       6
e5ae68df-fa3e-428d-81cd-29c195f4397d    752     CleanMAT -TOILET CLEANER FLASH OUT      \N      f       \N      7.07444444      f       7.074
6db870ad-1abd-47da-9708-853d17d33d7f    745     CleanMAT -TOILET SOAP-75 GRMS   \N      f       \N      2.1     f       2.25
3b5c7b38-4d38-4b68-a1d1-c3fb9803c7a5    749     CleanMAT -WD-40 \N      f       \N      12.5    f       12.5
8331430d-0fdb-405b-90af-c2ec06c4247a    750     CleanMAT -WINDEX CLEANER        \N      f       \N      8.92666667      f       8.925
0269fee9-39c4-4bfc-a173-7f3d77a6995c    716     CleanToolsMAT -ALUMINIUM SHOWEL WITH WOODEN HANDLE      \N      f       \N      \N      f       206
1ee4653d-bd1c-4773-abc1-d2a4d854f13b    2309    ADEC Staff- Event Allowances    \N      f       \N      \N      f       \N
0ffa6128-e33b-4ba1-b655-cc4d0fafcb7f    717     CleanToolsMAT -CO CO BRUSH 12” WITH STICK       \N      f       \N      17.1    f       17.1
e3f5eea8-0683-44b2-9b93-325682d6c243    2185    CleanToolsMAT -CO CO BRUSH 24” WITH STICK       \N      f       \N      55      f       55
aea4f87b-860e-4946-81fb-a4042701f84a    714     CleanToolsMAT -CRYSTAL ASH TRAY \N      f       \N      4.5     f       4.5
28ce5e3e-5d76-48c7-ab47-23b36a469f86    1786    ClinicSRV -Joint Block/Medicate - Stifle        \N      f       \N      \N      f       0
66765bc5-f937-4071-b6b0-19f979447d20    2215    ClinicMAT - Kentuky Gold drench 780     f       1       35      f       35
95255d80-0585-40f6-adef-a876c041d8a0    2023    ClinicMAT -2 PDS SUTURE SWAGGED 1/2 CIRCLE NEEDLE-SET   284     f       1       \N      f       284
4e919d9e-42f8-4918-a3fb-9b86ef4f9aee    2249    ClinicMAT - 3M Littmann classic Stethoscope.    5       f       1       475     f       475
44f4e3d4-8e9d-46c1-a924-4e5911076941    747     CleanMAT -TOILET TISSUE ROLL 1X100      \N      f       \N      110.63  f       135
9110ad71-d5dd-476b-be9f-3392f3098930    711     CleanToolsMAT -DBL MOP BUCKT WITH TROLLY STEEL FRAME-SET        \N      f       \N      186.4   f       186.4
ab3f4d30-9488-409f-93d9-ae36206ea835    713     CleanToolsMAT -LIQUID SOAP CASE \N      f       \N      45      f       45
166d7552-c5f3-4895-8075-19e74f6d16b0    710     CleanToolsMAT -MOP TROLLY DOUBLE BUCKET- STEEL FRAME    \N      f       \N      \N      f       0
a3531394-8b2e-4f70-a0f3-780670681e3b    718     CleanToolsMAT -PVC GARDEN RAKE WITH HANDLE      \N      f       \N      19.89   f       19.89
b6e2bc1c-ba81-4b6b-8635-fa6fb6088f1a    715     CleanToolsMAT -SMALL SHOVEL     \N      f       \N      14      f       14
e7fce5a2-549f-4b21-b4c8-3590ddb369e0    2638    Cleaning Services       \N      f       \N      \N      f       0
c020e81e-7f53-45cc-ba59-9008b0db7cb8    2211    ClinicMAT - Dectomax    220     f       50      110     f       110
753c203e-e3d3-4ac3-b40f-b363c44a939a    2367    ClinicMAT - TMPS PASTE 500gm (Randlab)  373.35  f       \N      \N      t       265
69cc17b2-a4db-4736-9346-3c2f01c88773    276     ClinicMAT -ACP (100ml bottle)   189     f       100     188.99892357    f       189
c6565bad-688f-448b-a127-a14ed5c48c0e    379     ClinicMAT -Adapter LL (60pce/box)       903     f       60      903     f       903
3c85c601-3e07-457c-aa78-e604a6991b86    248     ClinicMAT -Alamycin 200mg/ml (100ml bottle)     37.05   f       100     \N      f       37.05
9a92223c-b130-450c-be27-175b5cd20691    361     ClinicMAT -Amikacin 500mg/2ml (5pce/box)        169.12  f       5       185.68  f       150
ca0e7eb0-6728-42b1-b3ba-bfeb085dfd7f    258     ClinicMAT -Ancesol 10mg/ml (100ml bottle)       63      f       100     63      f       63
b9bb0433-85e7-4e32-b4fe-bc2fbc546754    277     ClinicMAT -Animalintex  \N      f       10      317.15294118    f       330
cedb9f41-d4ac-4f56-ab01-33b3d1624ea6    344     ClinicMAT -Brown Gauze (12pce/pack)     193.2   f       12      193.2   f       193.2
f1383820-34d0-46c1-af5d-b0368a043731    300     ClinicMAT -Buscopan Compositum (100ml bottle)   189     f       100     191.01550388    f       190
a4cc86c6-1343-4674-bdd0-d1f3feb311e8    284     ClinicMAT -Butasyl (100ml bottle)       36.9    f       100     \N      f       36.89857142857143
04dcb35b-6e05-419c-ac91-4f6852d8193a    2130    ClinicMAT - Antihistamine tablets       5       f       1       5       f       5
fd735e6d-e51c-4583-aa4d-3ee9a68aae20    355     ClinicMAT -Calmex Equine 60g (24pce/box)        288.75  f       24      \N      f       288.75
dceba4f6-a5bc-4a50-97eb-008121b1489b    444     ClinicMAT -Colix Injection 50mg/ml (100ml bottle)       149     f       100     116.78475243    f       113
31a91729-398b-4c5c-81b1-89daf72b7fc5    2568    ClinicMAT - Cepesedan 20 ml     373.35  f       20      360     f       360
07e360bc-92f2-4eac-beb4-0cac5e8b0101    2368    ClinicMAT - Dexa 5% Inj 373.35  f       50      77      f       77
13e04e75-4975-4251-b6c2-c225c76e93db    2197    ClinicMAT - E-Guard     60      f       1       \N      f       0
fa2703c6-eee4-4766-aae8-4bffffc4d4ae    298     ClinicMAT -Catasol (100ml bottle)       73.58   f       100     73.57625        f       73.58
e4fcd672-a092-40c5-af8e-00fb9b9ec577    279     ClinicMAT -Colvasone (50ml bottle)      39.21   f       50      \N      f       35.643478260869564
c68ecaa0-f3b7-4c89-82e4-164d6a6a0b42    442     ClinicMAT -Disposable Ambu Bag Large (Adult size)       89.25   f       \N      89.25   t       89.25
e7e12362-3b78-46e8-b6f3-f34462e32b6f    289     ClinicMAT -Diurazone (50ml bottle)      130.2   f       50      130.2   f       130.2
3674a3c7-d01d-46ec-8133-5c9859b6090a    440     ClinicMAT -Doxapram (20ml bottle)       252     f       20      252     f       252
a46629db-843b-46b3-bd1f-c786a900f21e    2381    ClinicMAT -Engemycin 10%        \N      f       100     102.62846715    f       104
d09293ab-4fb8-470f-9df3-37087aea5212    332     ClinicMAT -Equinate Inj (12 x 2ml vial) 1980    f       1       165     f       165
390c3ff7-f94b-49d5-bf66-bfe18c4d9504    2509    ClinicMAT -Examination Gloves M (100/Box)       \N      f       1       7       f       7
8b2651df-70c4-429e-8a71-f1a22820a4aa    376     ClinicMAT -Excede (100ml bottle)        \N      f       100     \N      f       622.5
d9300ff4-7a1b-4d9f-8154-69c28962fe49    349     ClinicMAT -Flunidol 33g Paste   520     f       6       520     f       520
8bdc7827-15b9-4b15-b341-08598255ab11    255     ClinicMAT -Gastrogard (7 syringes/box)  684     f       7       737.65434373    f       770
72000ef0-90cc-42c0-b00c-2388286e5b39    228     ClinicMAT -Gentamicin (100ml bottle)    \N      f       100     76.12765957     f       200
58098436-6b6d-4db1-86a7-4d73c40e0da7    2414    ClinicMAT -HY_50 Vet 17 MG/ML-3ml       5       f       1       \N      f       175
af1efead-b850-461b-949b-86b2b8d4a83c    257     ClinicMAT -Hemo-15 (100ml bottle)       158     f       100     78.97647059     f       78.98
b79eb1e5-41a4-4a90-9659-0bd2771ef9b0    399     ClinicMAT -Hypodermic Needles (100pce/box)      367.5   f       100     367.5   f       367.5
612e5ad2-02ab-4994-9a3d-b056503c561c    1928    ClinicSRV -Ultrasound Exam (Abdomen)    \N      f       \N      \N      f       0
33c03346-c4fa-4229-8357-1aca5a71171d    2024    ClinicMAT -2-0 Prolene - BOX    275     f       1       \N      f       275
da9d3715-47a4-4aa5-a20a-a81bc0279e55    451     ClinicMAT -23G NEEDLES 100/BOX  \N      f       1       \N      f       488
eee28e9f-ea8e-4984-8b3e-5d7deedf6010    391     ClinicMAT -Activated Charcoal 250g      37.8    f       1       37.8    f       37.8
e6892262-6678-410a-b4f5-beca87c8dc15    259     ClinicMAT -Imizol (50ml bottle) 147     f       50      147     f       147
72e61a8d-d098-4d80-8fa5-746ea30665e0    297     ClinicMAT -Jelonet 10x10cms (10pce/pack)        76      f       10      75.995  f       75.995
a861954d-acf1-4b54-8d58-5fb0e14fc2c9    262     ClinicMAT -Ketamine (25ml bottle)       72.57   f       25      72.56875        f       72.56833333333333
ec5c9101-547f-49e1-82a2-641315d8afb8    232     ClinicMAT -Marbocyl 10% (50ml bottle)   \N      f       50      181.58  f       181.58333333333334
18a7fd99-032f-47d3-88e2-9482c2f5469f    233     ClinicMAT -Metacam (50ml bottle)        \N      f       50      \N      f       120
eb0435f5-0a4b-457a-8422-dfb8d37e53f4    362     ClinicMAT -Metrolog Tablet 500mg (24 tablets/pack)      20.66   f       24      20.65752554     f       20.6575
3b45bffd-a1fc-421b-92eb-1f8fa7c3e8c3    269     ClinicMAT -Neutradex (1ltr bottle)      \N      f       1       \N      f       147
d57435ee-c85d-4511-a1a2-3214629b1ee2    400     ClinicMAT -Normal Saline 0.9% - 5ltr (2pce/box) 72.26   f       2       47.74526316     f       44.5
10e3cf06-8010-4f33-a40f-37c9e0d35a4d    271     ClinicMAT -Ornipural (100ml bottle)     45.34   f       100     45.34   f       45.34
9ab5f3f0-c96a-4ca6-af56-9e9b723e9f96    237     ClinicMAT -Oxytocin 10IU/ml (50ml)      32.59   f       50      32.59   f       32.5925
f1fdb0a5-00be-444f-a4e5-f200d1bf046f    273     ClinicMAT -Penstrep 20/20 LA (100ml bottle)     32.84   f       100     \N      f       32.84
993d5190-f8eb-4c97-9234-fb77db181ca7    416     ClinicMAT -Potassium Chloride 15% (5 vials/box) 34      f       5       34      f       34
496267dd-4e18-4d8e-8833-fb7b6aa9fddd    2781    ClinicMAT -Randlab TMPS Paste 250g      200     f       1       135     f       135
08215fbf-7692-4be3-ba6f-00c89c6aea45    239     ClinicMAT -Red Cell (1gallon)   140.72  f       1       140.72  f       140.71857142857144
7fa06ac3-9c37-499d-9a6f-7e4a90917384    296     ClinicMAT -Regumate (1ltr bottle)       1030.32 f       1       \N      f       1150
dae09228-c921-4b5d-9e6c-87e5a2daea20    274     ClinicMAT -Sarapin      247.92  f       1       225     f       225
faaa771d-b97f-4a61-839e-f49b59802d91    222     ClinicMAT -Sedator 10mg/ml (20ml bottle)        326.9   f       20      \N      f       409.1111111111111
41f2696c-5061-48a2-a267-84f0f82c1b40    421     ClinicMAT -Adrenaline   46.93   f       5       46.928  f       46.928333333333335
09e5ea1e-bdbd-40c5-bf88-144ac5736c32    242     ClinicMAT -Soffban (12pce/pack) \N      f       12      128.49333333    f       36
40906273-a918-45e5-88ed-9a764ae8f47b    347     ClinicMAT -Stride       552     f       1       459.994 f       460
0a48dcd3-3caf-4c68-afce-9a43c9106865    449     ClinicMAT -TEM-RUBBING ALCOHOL 5 LTR.   \N      f       1       \N      f       55
1a1f0d1c-f6e8-4449-bfb3-d72a7f928b57    433     ClinicMAT -Tripart (100ml bottle)       141.75  f       100     141.75  f       141.75
a15a21b9-374c-48ea-b143-3e7ae1349792    429     ClinicMAT -Ventipulmin Injection (50ml bottle)  266.44  f       50      266.4375        f       266.4375
cb977323-d2c1-4c9c-864c-f589e8196dc6    252     ClinicMAT -Xylazine 100 (50ml bottle)   121.12  f       50      121.12676056    f       121.11764705882354
57429aed-2879-493d-b541-71347a13266a    2513    ClinicMAT- Proteqflu- TE-FL1DOS 5       f       1       63.81491228     f       63.82
876686a7-a02d-4216-ad73-d93996049018    2061    ClinicMAT- Veterinary Disinfectant F10 SC 5L    917     f       1       880.32  f       917
3d1a7667-7ce9-4b29-aff4-bc6b5d2010c1    2057    ClinicMAT-Equipalazone Powder   \N      f       100     614.45730028    f       684
8edcd055-bbc6-44de-93fe-00c0b4d1aff1    2630    ClinicSRV - Bacterial + Fungal Culture + Sensitivity    270     f       \N      \N      f       0
929098fe-71eb-4e95-9bd9-af34794eee66    2581    ClinicSRV - Enalees Respiratory Swab PCR (EHV1+4, Influenza, Strangles) 315     f       \N      \N      f       0
784401d7-ebaf-4a4e-88f9-582444c512fd    2184    ClinicSRV - Enalees Strangles PCR Test  315     f       \N      \N      f       0
e59253cc-756b-454d-b815-952904023ff7    2081    ClinicSRV - Flu Vaccination     120     f       \N      \N      f       0
e74f4264-9f6d-4cf1-b470-e338374938bd    2569    ClinicSRV - Fungal culture + sample interpretation      270     f       \N      \N      f       0
5e4aa650-64a6-4328-9fd0-bf0458a1c7cb    2577    ClinicSRV - Intralesional injection (Ultrasound Guided) 300     f       \N      \N      f       0
4ff3d747-60ce-4557-86d0-c620eed039a9    2570    ClinicSRV - Lab - Haematology/biochemistry/electrolytes + interpretation        \N      f       \N      \N      f       0
bb39618d-6eca-4dcb-93a0-39e82d4fdc45    2803    ClinicSRV - Lab - Piroplasmosis PCR (urgent testing)    520     f       \N      \N      f       0
e455881e-8358-477a-976c-f03856be9e7b    2656    ClinicSRV - Laser Therapy       \N      f       \N      \N      f       0
7357bb1d-33a3-4950-8891-4c1b8482f1ec    2283    FUEL FOR EVENTS \N      f       \N      \N      f       \N
f9a7f2c2-3216-4732-85ea-f1ef4a6db142    2080    ClinicSRV - Monthly SP Check Up 150     f       \N      \N      f       0
848a549e-3c5b-4647-93bd-f9059db5522c    2578    ClinicSRV - Sedation For Travel 140     f       \N      \N      f       0
7b4c0245-b2b5-403e-86b2-dc9b3891108e    2567    ClinicSRV - Steroid     50      f       \N      \N      f       0
5a177a90-f5d7-456d-b891-911194361660    2082    ClinicSRV - WNV Vaccination     150     f       \N      \N      f       0
81b15789-c512-409f-8ae2-1ddb01b21712    1792    ClinicSRV -Abdominocentesis     \N      f       \N      \N      f       0
718bbe4d-526c-4be9-a0d8-b25eda4df34f    1731    ClinicSRV -Apply Poultice       \N      f       \N      \N      f       0
3bba8890-8f31-4721-a1eb-23b1bc82b540    250     ClinicMAT -Vetwrap      \N      f       1       4       f       4
58ac3468-68be-4292-a89c-e54113afe127    1727    ClinicSRV -Apply/Change Bandage \N      f       \N      \N      f       0
c8308151-d2ed-4646-891b-0190d151dd8f    1720    ClinicSRV -Back Injection       \N      f       \N      \N      f       0
f42c20e0-69ae-4b12-9868-f9f1a68f4321    1728    ClinicSRV -Bandage Simple       \N      f       \N      \N      f       0
3e29dbc5-e938-4859-828a-6f0fa82f202e    1788    ClinicSRV -Block/Medicate - Navicular Bursa     \N      f       \N      \N      f       0
24ab58d8-3e2c-4b9b-9788-e2436cbabd82    1789    ClinicSRV -Block/Medicate - Tendon Sheath       \N      f       \N      \N      f       0
b110a6f2-8fcc-44fd-b2e7-ab9db81e1934    1759    ClinicSRV -Block/Medicate Back  480     f       \N      \N      f       0
9beea7c0-ef71-41f6-9079-a297de0ffe18    1762    ClinicSRV -Castration (Standing)        \N      f       \N      \N      f       0
d3588155-8565-4f60-85c9-613620daf524    1917    ClinicSRV -Consultation - After Hours   360     f       \N      \N      f       0
9e712bea-c461-4de4-86d8-14bbae8edec4    2631    ClinicSRV -Consultation - Assesment for Insurance       240     f       \N      \N      f       0
96f4a9ae-e972-4dee-bd40-8e8223f2d4c6    1921    ClinicSRV -Consultation - Colic (Clinical Exam) 240     f       \N      \N      f       0
61b41f16-062d-46cd-b5d2-17f75cbce11c    1767    ClinicSRV -Consultation - Lameness + Ridden Assesment   \N      f       \N      \N      f       0
aa2f3071-dc4d-4f3b-9b10-944ce1077803    1766    ClinicSRV -Consultation - Lameness Exam \N      f       \N      \N      f       0
4f4d552d-1ae4-4dc5-b0b5-f0ef404077ba    1918    ClinicSRV -Consultation - Standard      240     f       \N      \N      f       0
c75a5eab-2131-4e8c-a5c7-5c1ce69c3eec    1920    ClinicSRV -Consultation Recheck 120     f       \N      \N      f       0
05e28e05-df88-4bd8-b38b-5fcad1a689be    1718    ClinicSRV -Consultation Short   \N      f       \N      \N      f       0
8214041f-a95b-4cd8-a67d-ee569188e77c    1790    ClinicSRV -Contrast Tenogram    \N      f       \N      \N      f       0
4dc4f990-2866-4a48-8c7d-e3dcc1aaae2a    1730    ClinicSRV -Dental - Wolf Tooth Extraction (per tooth)   \N      f       \N      \N      f       0
feb9c32d-24b5-47cb-97bc-a7297557695b    1729    ClinicSRV -Dental Rasp - Routine        300     f       \N      \N      f       0
1a8f7ce7-bdad-4008-8dff-ab9b062011e7    2279    ClinicSRV -Dental Rasp - Routine SP     250     f       \N      \N      f       0
811fc5a4-8094-48fd-9508-437ce8f31223    1922    ClinicSRV -Endoscopic Exam      \N      f       \N      \N      f       0
471fd48c-3e10-400c-8fd3-be13e3e88018    1732    ClinicSRV -Epidural Only        \N      f       \N      \N      f       0
e3d52a59-de8a-4400-b7d4-140ef9408ee1    1806    ClinicSRV -Euthanasia Fee       \N      f       \N      \N      f       0
061325d4-3ec1-4b83-a4f4-f5238129b60f    1803    ClinicSRV -Export Paper Fee     \N      f       \N      \N      f       0
df64441c-b169-41aa-aa81-e68494a2a232    1800    ClinicSRV -External Lab Fee     \N      f       \N      \N      f       0
513f0706-ea62-482e-acd0-bd43b9887163    1812    ClinicSRV -External Lab Fee - Strangles ELISA   360     f       \N      \N      f       0
38d0f709-5e2b-451e-9cda-aae853e18bf4    2832    ClinicSRV -External Lab Fee - Strangles ELISA (urgent fee)      150     f       \N      \N      f       0
98fa4a6e-3c2b-47c8-a503-e6605cc1a90d    1813    ClinicSRV -External Lab Fee - Strangles PCR     \N      f       \N      \N      f       0
f7f2aa56-dfa2-49e8-86c4-4cf774c6ab94    1804    ClinicSRV -Formal Letter Fee    \N      f       \N      \N      f       0
9d13eb48-9553-4f59-bf9d-6b283cdf826a    1923    ClinicSRV -Gastroscopy Exam     740     f       \N      \N      f       0
22e01a44-6a4b-4f85-b52e-c87bc70ac7d4    1721    ClinicSRV -Gastroscopy Exam - Recheck   \N      f       \N      \N      f       0
c9fcb526-793f-494b-8505-5db38362e75b    1761    ClinicSRV -Guttural Pouch Lavage        \N      f       \N      \N      f       0
039f15bd-87e3-40bd-8853-c11df2c31701    1752    ClinicSRV -IA/IT Fine Needle Lavage - Septic Joint      \N      f       \N      \N      f       0
72ec661f-d53b-476a-b7df-2523378e0f91    1734    ClinicSRV -IV Catheterisation - Long Stay       \N      f       \N      \N      f       0
2af709ab-7e98-4ab6-aec4-cb51dd2efe84    1733    ClinicSRV -IV Catheterisation - Short Stay      \N      f       \N      \N      f       0
a0eddf2e-eaf7-4f88-9907-86a7f6ba443d    1753    ClinicSRV -IV Fluid Administration      190     f       \N      \N      f       0
83f82e0b-1fb1-4c51-ae07-914d9908b2a1    1735    ClinicSRV -IV/IM Injection Fee  70      f       \N      \N      f       0
a9c6e196-6b2c-4349-b368-85508242b125    1747    ClinicSRV -Intravenous Regional Perfusion (IVRP)        \N      f       \N      \N      f       0
d60957ca-dd25-4d1a-8157-53f3a52f966f    1782    ClinicSRV -Joint Block/Medicate - Carpus        \N      f       \N      \N      f       0
cbed1f9a-d3f4-440d-a8be-75a537fbd9da    1760    ClinicSRV -Joint Block/Medicate - Cervical Facet Joint (Ultrasound guided)      \N      f       \N      \N      f       0
16b787e1-e9eb-4253-b02b-f75a0747e4a4    1779    ClinicSRV -Joint Block/Medicate - DIP   300     f       \N      \N      f       0
51d8cc3a-3694-45df-a75f-2fb3f3be5a17    1784    ClinicSRV -Joint Block/Medicate - DIT   \N      f       \N      \N      f       0
b35649fd-0d77-4ea6-a6e6-3f913448911f    1781    ClinicSRV -Joint Block/Medicate - Fetlock       \N      f       \N      \N      f       0
78e1c4da-1cf5-4ad2-8ff4-7c6e3a530216    1787    ClinicSRV -Joint Block/Medicate - Miscellaneous \N      f       \N      \N      f       0
9e2ec26d-2c40-42ca-b10a-aa241f21c6bf    1780    ClinicSRV -Joint Block/Medicate - PIP   \N      f       \N      \N      f       0
4dda5637-1500-46fd-83e0-59f79a3caf95    1757    ClinicSRV -Joint Block/Medicate - Sarco-iliac (Ultrasound guided)       300     f       \N      \N      f       0
9be7dd7a-0d14-459b-8f1d-11caceabfc6d    1783    ClinicSRV -Joint Block/Medicate - TMT   300     f       \N      \N      f       0
897febf5-1472-41fe-baee-c5a467d1a3ed    1758    ClinicSRV -Joint Block/Medicate - Thoracic/Lumbar Facet Joint (Ultrasound guided)       \N      f       \N      \N      f       0
5ed910a9-57e5-4495-a340-8fb5ab134613    1785    ClinicSRV -Joint Block/Medicate - Tibiotarsal   \N      f       \N      \N      f       0
0e2249b7-c0fd-4ce6-adc6-08afdd9e8d09    1764    ClinicSRV -Lab - Blood Gas Analysis     \N      f       \N      \N      f       0
bf0c4f0c-489b-4ca1-b92b-6b514e213f66    1765    ClinicSRV -Lab - Faecal Egg Count       \N      f       \N      \N      f       0
e6149f99-35ea-483c-a8a0-01dc1128ffc1    1724    ClinicSRV -Lab - Sample Collection      \N      f       \N      \N      f       0
b7c01195-ad27-4d10-bc75-f605bb4c4a67    1722    ClinicSRV -Lab Biochemistry Per Test    180     f       \N      \N      f       0
640039fb-dd0f-4d05-a655-77eb059c7c04    1925    ClinicSRV -Lab Blood PCV/TP     \N      f       \N      \N      f       0
5ffe7fb3-7a24-4804-b94d-55e29940e5da    1793    ClinicSRV -Lab Fee Joint Sample \N      f       \N      \N      f       0
efbbeb81-44bb-4f72-8a2a-0ea6020742bd    1924    ClinicSRV -Lab Haematology      125     f       \N      \N      f       0
a3a9985b-b8c5-49b0-b0d8-94c09f8aee8f    1801    ClinicSRV -Lab Sample Transport Fee     350     f       \N      \N      f       0
8265b777-5fa2-4c22-927a-84db5c441c45    1926    ClinicSRV -Lab Urinalysis       \N      f       \N      \N      f       0
75f8998f-cced-404c-9a7a-587e61b7800f    1726    ClinicSRV -Laser        \N      f       \N      \N      f       0
cc0a7c79-e7b4-4145-a0de-91f9e9e8deca    1736    ClinicSRV -Nasogastric Tubing   \N      f       \N      \N      f       0
8995e8d6-c06f-46d9-b65e-fd8c5d8a6d81    1737    ClinicSRV -Nebulisation \N      f       \N      \N      f       0
5b2c8e4b-f4b2-4c45-aa3c-4f971a2a7b69    1771    ClinicSRV -Nerve Block - Abaxial Sesamoid       \N      f       \N      \N      f       0
45266690-40f9-4721-8bd2-1220c71d2956    1778    ClinicSRV -Nerve Block - Deep Branch Lateral Plantar Nerve      \N      f       \N      \N      f       0
f1d36aca-f607-4b37-b233-1214a2132c3f    1777    ClinicSRV -Nerve Block - Dental \N      f       \N      \N      f       0
97659b71-76dc-4d64-8415-ecd843039e6a    1776    ClinicSRV -Nerve Block - Eye Examination        \N      f       \N      \N      f       0
487d74c1-c527-4ff3-9310-d78c22a7c543    1773    ClinicSRV -Nerve Block - High 4/6 Point \N      f       \N      \N      f       0
520539ba-dc7a-4f60-952b-29f3bb20f70e    1772    ClinicSRV -Nerve Block - Low 4/6 Point  \N      f       \N      \N      f       0
66b2f390-180a-4d07-8f32-967767dbc034    2205    ClinicMat - E45 Cream 350g      108.9   f       1       \N      f       145
a3d16da4-e130-44b7-a4bb-cc4ac37d83bd    1774    ClinicSRV -Nerve Block - Median/Ulnar   \N      f       \N      \N      f       0
f1567c9c-be47-4be0-9005-2bbd561bf765    1770    ClinicSRV -Nerve Block - Palmar Digital Nerve Block     \N      f       \N      \N      f       0
f9581801-edba-4434-bbb2-c9ace1b45e55    1809    ClinicSRV -PPE Xray Package 1: Front Feet and Hocks     \N      f       \N      \N      f       0
2904edff-764f-4ac4-86cd-9f20e8be4bfa    1810    ClinicSRV -PPE Xray Package 2: Front Feet, Hocks, Fetlocks, Stifles     \N      f       \N      \N      f       0
6b109571-1a7b-4d1f-a9a5-fb85fb82e39b    1811    ClinicSRV -PPE Xray Package 3: Front Feet, Hocks, Fetlocks, Stifles, DSPs       \N      f       \N      \N      f       0
26c20b57-4dd6-439e-9c86-35643115bee4    1751    ClinicSRV -PRP Treatment        \N      f       \N      \N      f       0
f0c815d5-b411-4546-97f0-34b9a7dae39f    1795    ClinicSRV -Pack Feet For Radiography    \N      f       \N      \N      f       0
faa3a70a-e7ee-4f15-af13-a5d368ee6290    1798    ClinicSRV -Passport ID  \N      f       \N      \N      f       0
4a63cca3-7d8e-4bd6-b2ff-f84b40071d63    1738    ClinicSRV -Post Mortem Exam     \N      f       \N      \N      f       0
7ce3a452-0bc0-4423-924b-7a0a822daa71    1763    ClinicSRV -Castration (Under GA)        \N      f       \N      \N      f       0
d0e425d6-9002-4767-85e7-ce4ce324d757    1807    ClinicSRV -Pre-Purchase Exam - 2 Stage  700     f       \N      \N      f       0
f988eb97-f452-4c9a-bc84-bf71cd195ff3    1808    ClinicSRV -Pre-Purchase Exam - 5 Stage  \N      f       \N      \N      f       0
40b2df37-cad7-4df3-9000-9a9d84d51c01    1802    ClinicSRV -Prescription Fee     \N      f       \N      \N      f       0
294fded9-4305-48d7-b273-0d09056d2b02    1794    ClinicSRV -Radiography (Per Additional View)    120     f       \N      \N      f       0
7ee96585-9bcf-445f-af5d-ec75763fef82    1927    ClinicSRV -Radiography (Set Up Fee + 1st View)  190     f       \N      \N      f       0
2ee6785f-197b-4ab2-9583-eb41f8ceb0d8    1739    ClinicSRV -Rectal Examination   125     f       \N      \N      f       0
669d1f00-f8d6-4d86-870d-5d48cf7cfcfb    1749    ClinicSRV -Rectal Examination Recheck   \N      f       \N      \N      f       0
78f1047e-6c36-4cc1-9eff-a5ef940dea86    1796    ClinicSRV -Remove Shoe  \N      f       \N      \N      f       0
cde77c22-7efb-47f5-a23f-62c5e1e32016    1740    ClinicSRV -Sedation Fee 175     f       \N      \N      f       0
cb849f39-2cb0-4c35-a03c-953402a8132d    1750    ClinicSRV -Shock Wave Therapy Per Session       \N      f       \N      \N      f       0
73bd38e0-c31d-48bb-8475-a04e24f7735a    1741    ClinicSRV -Stitch Up Standing Complex   \N      f       \N      \N      f       0
5b5bd384-bc47-4779-a642-d0248cb535e7    1742    ClinicSRV -Stitch Up Standing Simple    \N      f       \N      \N      f       0
6ffa6772-b9b5-4b44-9f3d-9f509db82b59    1791    ClinicSRV -Synoviocentesis      \N      f       \N      \N      f       0
31f21f3e-ac2d-45eb-9cb9-fe53841437b6    1799    ClinicSRV -Take Nasopharyngeal Swab     100     f       \N      \N      f       0
85f64519-f828-4a09-ad48-d815c719c7a3    1805    ClinicSRV -Telephone/Video Consultation Fee     \N      f       \N      \N      f       0
85cf0ae1-3528-4592-a3ba-6f91bf95863b    1743    ClinicSRV -Thoracocentesis      \N      f       \N      \N      f       0
f66efe06-8202-43b7-8137-c15af2e85ffc    1754    ClinicSRV -Tooth Extraction     \N      f       \N      \N      f       0
3f298ab9-a8f7-4c94-97ea-84c051a9cce6    1723    ClinicSRV -Tracheal Wash Cytology Lab Fee       \N      f       \N      \N      f       0
edc7d7ae-4e8b-4a37-8aa4-00bee9186849    1769    ClinicSRV -Ultrasound Exam (Brief)      \N      f       \N      \N      f       0
5ee94bad-2d8e-4c47-ba93-fd806a113fd2    1929    ClinicSRV -Ultrasound Exam (Cardiac)    \N      f       \N      \N      f       0
f3428cfb-d0ff-4a6f-b13c-9e42b4cf1e84    1768    ClinicSRV -Ultrasound Exam (Tendon)     400     f       \N      \N      f       0
10cb955d-f9ca-4602-a517-9109f89b2dfa    1719    ClinicSRV -Ultrasound Re-Check  \N      f       \N      \N      f       0
834900c6-97ec-4aa8-a3b9-eee40c4eca15    1717    ClinicSRV -Ultrasound Reproduction      200     f       \N      \N      f       0
b3491f64-29b1-431b-b92d-2889cf1c7b2c    1744    ClinicSRV -Urinary Catheterisation Fee  \N      f       \N      \N      f       0
23d52900-935e-475f-b099-2d02f0ac3d2e    1745    ClinicSRV -Uterine Lavage       \N      f       \N      \N      f       0
dfa5f8c4-8323-48c3-8e01-e4b5bb80b24d    2831    ClinicSRV -Visit Fee Extended   600     f       \N      \N      f       0
2ff1dc27-1d89-451d-9e33-deda80c3f31c    1919    ClinicSRV -Visit Fee Standard   \N      f       \N      \N      f       0
a2f0f0e0-c225-434a-99f0-2006714151c7    1746    ClinicSRV -Wound Cleaning       \N      f       \N      \N      f       0
02f784a7-a2ff-42a6-946f-95993de942ea    1748    ClinicSRV -Wound Cleaning + Sutures     \N      f       \N      \N      f       0
eeb6c0f0-0d1c-44db-bbfb-8b230100d7f6    2358    Difficult Horse / Heavy Horse Fee       275     f       \N      \N      f       0
2f761a93-8daf-4d16-8a10-99cce6312acd    2643    Dilaps and Wall Removal.        \N      f       \N      \N      f       0
7984855b-2ee0-4fa5-8505-a53eeccd4e25    2357    Dorsal Wall Resection   250     f       \N      \N      f       0
5442cf66-b16b-42f1-97d2-47a8c349056e    463     ElectricalMAT -Electrical-Electrical    \N      f       \N      75      f       75
6a7cda88-bde0-4731-910d-987d77593dab    465     ElectricalMAT -GE PAR LAMP      \N      f       \N      85      f       85
90ee975c-d49c-4f41-943d-b4362bbdc0b8    466     ElectricalMAT -MULTI METAL LAMP \N      f       \N      18.5    f       18.5
c2c5d529-1444-43a1-a368-51f06e876a0c    464     ElectricalMAT -PHILIPS 1000W    \N      f       \N      65      f       65
ceb983ce-0acf-4d9f-a417-2444b8383a40    2551    EquestiranMAT - Garrard Snuff Box with Lapel Pin        \N      f       \N      13519.432       f       13519.432
c33f04f4-74cf-4983-ae46-b74bdbd5106b    2533    EquestiranMAT -45CM TROPHY STERLING SILVER      \N      f       \N      248966.3        f       248966.3
88425c79-69e9-45dc-89e2-922a120a8397    1613    EquestiranMAT -ADEC HANGING GIFT        \N      f       \N      30      f       30
61385324-706f-48a9-b482-7f20ee838c4e    1623    EquestiranMAT -ADEC KNIFE       \N      f       \N      40.5    f       40.5
81b6e6bc-1a57-4ac8-b36d-9232c1089000    1612    EquestiranMAT -ADEC SHIFON PALQUE       \N      f       \N      90      f       90
8195f831-5c6c-4f08-b51f-caa4b018eb3c    1611    EquestiranMAT -ADEC WOOD PLAQUE \N      f       \N      95      f       95
3c8db0be-b7c3-4650-a566-37a4fe9245ad    2583    EquestiranMAT -Abu Dhabi Derby Sculpture Trophy Set     \N      f       \N      \N      f       25950
47677b0f-1a30-43ac-9119-6d6577027209    2314    EquestiranMAT -Abu Dhabi Gold Cup Trophy Set 2025       \N      f       \N      \N      f       11500
86faec53-cf3f-4c75-944b-4f8bd635e02b    2303    EquestiranMAT -Ajzal Showjumping Trophy Set Season 2025 \N      f       \N      \N      f       1375
5738ba49-821e-49a1-9061-f2c72d99aba6    2083    EquestiranMAT -Ajzal Trophy Set of 3 Race Season 24-25  \N      f       \N      \N      f       40674
53a97c09-0ff7-45b4-ac0c-109aaf243495    1606    EquestiranMAT -BADGE WITH ADEC LOGO     \N      f       \N      111.74857143    f       111.74875
f2a4222e-5e61-40ff-9bd5-aaecd409fc00    1620    EquestiranMAT -CRYSTAL BIG DIAMOND TROPHY YEAR '09-'10  \N      f       \N      105     f       105
aafeec31-84a7-4bae-8308-0c2dab25158c    1626    EquestiranMAT -CRYSTAL CUP BIG W/ BASE AND PLATE        \N      f       \N      \N      f       225
d97e7583-f10a-4ed7-ab2b-f407d6c385b5    1622    EquestiranMAT -CRYSTAL LARGE TROPHY YEAR 11-12  \N      f       \N      95      f       95
187afcb9-5d81-4c4a-a907-738fc3157945    1636    EquestiranMAT -Crystal Trophy Set of 3 – SJ 1   \N      f       \N      935     f       935
966b6541-5332-4112-b186-791a1e26177c    1608    EquestiranMAT -FLOWER VASE      \N      f       \N      35      f       35
1993f08b-923e-4d27-b6c9-6cb09c096bc6    1621    EquestiranMAT -GOLD GAVA CUP TROPHY     \N      f       \N      175     f       175
daf7aab3-cb9a-4a44-9f64-e68ac0881251    1618    EquestiranMAT -HORSE BIG TROPHY CERAMIC \N      f       \N      750     f       750
9f0e9294-b91e-4fa8-8ed9-8bfe8e29797f    1610    EquestiranMAT -HORSE HEAD METAL TROPHY  \N      f       \N      275     f       275
1a45abd3-e36b-42e4-b824-8cc343473243    1607    EquestiranMAT -HORSE LOGO       \N      f       \N      120     f       120
77440f66-d0a6-442f-8206-d00b93f7cbd6    1631    EquestiranMAT -HORSE MAGNATIC STICKERS  \N      f       \N      \N      f       7.5
2cd60e1e-c0a6-497a-9784-757a2de9afdf    1619    EquestiranMAT -HORSE MEDIUM TROPHY CERAMIC      \N      f       \N      600     f       600
0b989732-bf6b-4a09-8728-e723cf69a107    1609    EquestiranMAT -HORSE SMALL TROPHY       \N      f       \N      576.25  f       576.25
5929b867-7b64-4974-966b-4abf7b756395    1615    EquestiranMAT -METAL STAND GIFT \N      f       \N      10.75   f       1050
b1967932-18c9-49b8-8e15-57875387068d    1634    EquestiranMAT -Metal trophy (23 cm with etching and     \N      f       \N      2006.67 f       2006.67
9b6e13f4-a665-4535-8398-b9413d1ea87b    1614    EquestiranMAT -NUMBER BOARD     \N      f       \N      10.47   f       10.47
c36c7472-e6a3-4a93-9f77-cfa9a9191c69    1632    EquestiranMAT -OMR/PICK 6 FORM PRINTING DUAL SIDE WITH BARCODE & DELIVERY       \N      f       \N      0.93172407      f       0.931724074074074
79ee8fe9-39ac-40ea-ad8e-2bd86ecb4021    1637    EquestiranMAT -PLAIN ROSSETTES  \N      f       \N      22.1228 f       22.122767295597484
d9e6e9aa-96db-4fbd-8f2c-46716b9d128c    1638    EquestiranMAT -ROSETTE 12mm Dia WITH RIBBON     \N      f       \N      28      f       28
df35e0c7-0e46-409c-ac4d-151f986238ba    217     ClinicMAT -Alluspray 72g        29.42   f       1       47.06   f       50
4a7e7696-d510-466f-a57e-ea55bbe70adf    2361    EquestiranMAT -Razzpura Horse Blank     \N      f       \N      \N      f       639.3586666666666
e8baed26-2a87-4910-bedb-cddd70f54b36    2360    EquestiranMAT -Razzpura Rosettes        \N      f       \N      \N      f       93.46177777777778
88f628e9-d5ec-4c90-a63d-b589332637e8    2359    EquestiranMAT -Razzpura Sachets \N      f       \N      \N      f       155.84333333333333
22190c30-5063-446a-b7da-8c771cc05401    1624    EquestiranMAT -SILVER BOAT TROPHY       \N      f       \N      4066.67 f       4066.67
406ae8b3-7ab1-4e5c-9bbc-cedc0ae0f33b    1627    EquestiranMAT -SILVER HORSE TROPHY SMALL        \N      f       \N      155     f       155
939fb293-ccdc-4eef-a16c-89379c6896fa    2455    EquestiranMAT -SPECIAL ROSSET   \N      f       \N      \N      f       30
d4097cbc-aea5-4518-841b-8c1789fc1082    2522    EquestiranMAT -Shamrock Rossette - EPR3 Sand Dune       \N      f       \N      40.57078886     f       40.5708
9f647f12-cdcf-4d5b-b063-4ce4b3cb99a3    2076    Consumable-Cleaning Item        \N      f       \N      0       t       \N
4350f4ef-c750-4a83-9450-77c0c54ab723    2078    Consumable-Refreshment  \N      f       \N      0       t       \N
31fc6d75-0cbe-4682-b035-f831fe055e1a    2077    Consumable-stationary Item      \N      f       \N      0       t       \N
893b6489-0a00-4b24-ab57-6b967079f90b    2222    Consumables - Hospitality Supplies      \N      f       \N      0       t       \N
9d4de784-f5f2-43da-9fac-cdb890a0642a    2508    Consumables - Kitchen Staff Supplies    \N      f       \N      0       t       \N
bb89639d-1634-4a38-9c19-0dc7d1ecc060    2227    Consumables -Horse Supplies     \N      f       \N      0       t       \N
66ca0c90-a923-4aa2-9936-ded9f4efea1e    336     ClinicMAT -Amescrub 5ltr        \N      f       1       72.565  f       72
39671b42-ae92-423d-8202-f34f5a4615d8    278     ClinicMAT -Apisal Drops 6.73    f       1       6.73    f       6.73
73436e4a-d667-4840-9e46-1cc340001a9a    219     ClinicMAT -Arnica Gel   256.48  f       1       \N      f       256.48
ecc3a5dd-f5c1-412d-8fb9-c36dfb390b39    1755    ClinicSRV -Plasma Administration Fee    \N      f       \N      \N      f       0
9675c64e-6119-4e75-b845-d13f0ca402de    2056    Discount 10%    -10     f       \N      0       f       0
2c78c019-bf71-4937-a7b1-80f63a19beac    2262    Discount 15%    -15     f       \N      0       f       0
1db99227-98f5-4ed4-8bf8-6d8d922afe5d    2263    Discount 20%    -20     f       \N      0       f       0
77d9f7e7-9d47-46a1-8443-9fa8b63510b8    2521    EquestiranMAT -Shamrock Rossette - JP2 Cream    \N      f       \N      24.1539 f       24.1539
3d22a53a-eee3-492b-9044-431bbaf65e28    2520    EquestiranMAT -Shamrock Rossette - JP2 White    \N      f       \N      27.52554391     f       28.649416666666667
cd98c9e0-8f63-4bcf-8444-a399976d06eb    1630    EquestiranMAT -TROPHY (SET OF 3 SET)    \N      f       \N      1758.92763158   f       3483.3333333333335
372a66b4-08e1-4ea8-8bf5-3a6e8a069351    2575    EquestiranMAT -Trophy Bronze Gold Plate 35cm    \N      f       \N      \N      f       3650
d4fa8e98-68a7-4c46-ba88-88f0beabf7b2    2574    EquestiranMAT -Trophy Bronze Gold Plate 45cm    \N      f       \N      12000   f       12000
d8d11096-69f1-46f0-ba53-c45139ec7925    2576    EquestiranMAT -Trophy Bronze Silver & Gold Plate 35cm   \N      f       \N      \N      f       3400
90dec78e-a837-4d14-ad8d-bdacb36934d5    2573    EquestiranMAT -Trophy Bronze Silver Plate 30cm  \N      f       \N      1050    f       1050
c1a90bea-2cd4-4453-9b20-0cd89bf153b8    1617    EquestiranMAT -UAE TARPAULIN TEAM       \N      f       \N      135     f       135
dfddc3eb-c9b8-4505-b0b8-b9d271d222cc    1616    EquestiranMAT -UMBRELLA BIG (OLD)       \N      f       \N      15      f       15
18a7ea3c-a3c3-4838-b01a-9eee9f65662d    1605    EquestiranMAT -VASE FLOWER TROPHY       \N      f       \N      86      f       86
6b61bdda-49c3-4764-a2fc-1e06b3fdf494    1625    EquestiranMAT -WOODEN ADEC LOGO BIG (OLD)       \N      f       \N      65      f       65
07e18fe9-024d-4831-b8ba-c615541fb531    1628    EquestiranMAT -WOODEN HORSE TROPHY BIG  \N      f       \N      310     f       310
1a35fee3-69af-493f-a007-918a498f2748    1629    EquestiranMAT -WOODEN HORSE TROPHY SMALL        \N      f       \N      160     f       160
baf6c43a-a136-4a88-9109-1435a3bfd943    1633    EquestiranMAT -WRIST BAND       \N      f       \N      1.61    f       1.61
216bd3d0-d691-4185-bd96-65395c9d5be1    2582    EquestiranMAT -Yas Sculpture Trophy Set \N      f       \N      \N      f       25950
ccb36eb8-d68b-45c1-81a4-bdf30c6a542e    2789    Espresso Lab – Turnover Rent (Unbilled) \N      f       \N      \N      f       0
c081c196-a35c-4fcc-b2f7-b6ff12334c51    954     FarrierMAT -16X08B SHOES SIZE 27        \N      f       \N      10      f       10
1ecc12fc-8f56-479a-9954-6786378d09e1    953     FarrierMAT -18X07B SHOES SIZE 29        \N      f       \N      10      f       10
8f471598-e630-4fa7-87f7-b6d49a21bf07    951     FarrierMAT -18X7B SHOES SIZE 26 \N      f       \N      10      f       10
75e6bb33-f86d-4a6d-961a-7a5dd585ef08    2604    FarrierMAT -3/8" Treading Taps  \N      f       \N      110     f       110
9b856c13-ae1f-4be3-8670-c42f988f1df6    2469    FarrierMAT -3D Halfmesh Pad Narrow 3 Degree Black Size: 1 PAIR  \N      f       \N      82      f       82
97312232-88e8-4a8e-a156-4ce386184b8c    2470    FarrierMAT -3D Halfmesh Pad Narrow 3 Degree Black Size: 2 PAIR  \N      f       \N      82      f       82
397a0077-3bce-4690-bb61-7128fc5e1c8d    2471    FarrierMAT -3D Halfmesh Pad Narrow 3 Degree Black Size: 3 PAIR  \N      f       \N      82      f       82
d251e1bb-0635-4cf2-abba-2648e179daf7    2142    FarrierMAT -3D Halfmesh Pad Narrow 3 Degree Black Size: 4 PAIR  \N      f       \N      42.5    f       37.5
1f8ff75a-6cea-4aa9-bea5-208d86eee36b    2143    FarrierMAT -3D Halfmesh Pad Narrow 3 Degree Black Size: 5 PAIR  \N      f       \N      44.91666667     f       37.5
105f5c3f-3d9f-478b-b76d-b04fe23b7da7    2144    FarrierMAT -3D Halfmesh Pad Narrow 3 Degree Black Size: 6 PAIR  \N      f       \N      82      f       82
c6bc3ab5-3bbb-40ab-8ae4-12d742662e30    2145    FarrierMAT -3D Halfmesh Pad Narrow Flat Black Size: 4 Pair      \N      f       \N      \N      f       75
dac5189c-fd1a-40b9-ba9d-3e1cc824bec1    2146    FarrierMAT -3D Halfmesh Pad Narrow Flat Black Size: 5 Pair      \N      f       \N      \N      f       75
a86cd6e4-9adf-4028-979d-c8dc7c673936    2147    FarrierMAT -3D Halfmesh Pad Narrow Flat Black Size: 6 Pair      \N      f       \N      75      f       75
08551109-dbad-42e4-a81c-f074cf7b8e6f    1163    FarrierMAT -3M SANDING BLOCK    \N      f       \N      9.5     f       9.5
e7d1f094-f06c-4293-9176-d16815b6da86    1128    FarrierMAT -3rd Millennium Apron Big Size       \N      f       \N      990     f       990
84580dbb-4821-4d56-bccf-3f9bc5069b3f    999     FarrierMAT -A-CLASS 3X0 FRONT   \N      f       \N      10      f       10
abac2a31-bd7c-452d-aa46-da5ed494667d    1000    FarrierMAT -A-CLASS 3X0 HIND    \N      f       \N      10      f       10
913955cf-87e2-4e32-8378-d0c6b919ad10    2468    FarrierMAT -ACR 110 SIZE: 0     \N      f       \N      255     f       255
29085d37-a34f-4994-ac1c-85f0c115b6db    1149    FarrierMAT -ACR 110 SIZE: 1     \N      f       \N      260     f       260
f54573f2-22c5-4162-95d0-24793cecb4c5    1150    FarrierMAT -ACR 110 SIZE: 2     \N      f       \N      265     f       265
37e0f5cf-bf99-4c53-8e42-906db5327c03    1151    FarrierMAT -ACR 110 SIZE: 3     \N      f       \N      278.25  f       278.25
a0fe2e61-27ff-4d12-b75c-8093cb928e7e    1152    FarrierMAT -ACR 110 SIZE: 4     \N      f       \N      278.25  f       278.25
c8bf4788-9128-4db7-b7c3-a3469e024aa6    1153    FarrierMAT -ACR 332 SIZE: 1     \N      f       \N      320.25  f       320.25
e972a5e5-d9ed-4da7-9623-be21881169b9    1154    FarrierMAT -ACR 332 SIZE: 2     \N      f       \N      320.25  f       320.25
5ea1fb6b-f924-4a06-a578-16a37d3b656a    1156    FarrierMAT -ACR 332 SIZE: 4     \N      f       \N      330.75  f       330.75
a8eb23aa-d8c6-4094-85ec-59b1b8f4d446    1109    FarrierMAT -ACR 340 ALUMINIUM 3 CLIP SIZE 1 FRONT       \N      f       \N      115.5   f       115.5
6e6ca8c8-bce5-4e50-a14b-6653cb911f09    1089    FarrierMAT -ACR 340 ALUMINIUM 3 CLIP SIZE 2 EGG BAR FRONT       \N      f       \N      150     f       150
5c19978d-0771-4b6d-8ab8-46652e1e23fd    1087    FarrierMAT -ACR 340 ALUMINIUM 3 CLIP SIZE 2 FRONT       \N      f       \N      112.5   f       112.5
f7fccc25-8883-46a5-b026-adf19bbd2ec9    1110    FarrierMAT -ACR 340 ALUMINIUM 3 CLIP SIZE 3 FRONT       \N      f       \N      115.5   f       115.5
af342494-b4cb-4d98-84ce-25dee8c2df72    1088    FarrierMAT -ACR 340 ALUMINIUM 3 CLIP SIZE 4 FRONT       \N      f       \N      126     f       126
e67752ad-4047-4f07-b486-8bf42800be0a    1145    FarrierMAT -ACR 360 SIZE: 1     \N      f       \N      300     f       300
0e7faa73-448f-4c0a-91f8-0b1366f9c8e3    1146    FarrierMAT -ACR 360 SIZE: 2     \N      f       \N      310     f       310
3dde3944-2d77-4d42-82d9-37086f6d8b8d    1147    FarrierMAT -ACR 360 SIZE: 3     \N      f       \N      310     f       310
adfa97a9-2b2a-4fe3-9d3a-5b2b90218dc4    1148    FarrierMAT -ACR 360 SIZE: 4     \N      f       \N      315     f       315
71a041c1-5a50-4e46-9ec9-e24446222f05    450     ClinicMAT -BOVIVET GEL/LUBREL   63.12   f       1       63.1175 f       63.1175
352a62ff-edac-4454-a1d6-a5cbfc076ba7    1177    FarrierMAT -ACR 430 SIZE 0      \N      f       \N      310.08333333    f       310.0833333333333
9e99122f-d13b-4a5a-b676-3e99fccb29c0    330     ClinicMAT -Battles Wound Powder 125g    45.15   f       1       45.15   f       45.15
9af26c89-d0c1-4f55-ab32-f95411119109    281     ClinicMAT -Betadine Scrub (500ml)       31.29   f       1       31.288  f       31.288333333333334
7a69a5e1-6b0b-43bd-91c2-94b4589668be    280     ClinicMAT -Betadine Solution (500ml)    50.47   f       1       56.745  f       58
293ed662-3152-4973-8e56-569003034231    283     ClinicMAT -Biopsy Punch 12      f       1       12      f       12
54917120-3f27-4e9f-93cd-54c674cf441c    220     ClinicMAT -Biotin Plus  \N      f       1       \N      f       400
c0f35fb1-d03e-45bc-8820-2b79d7c6783a    282     ClinicMAT -Blood Collection Needle 20G 1.5"     55.41   f       1       55.405  f       55.406
150ada40-1bc0-4f1c-83b9-cc24f1e81c62    357     ClinicMAT -Blood Collection Tube (Green - 5ml)  36.68   f       1       36.684  f       36.68333333333333
998dde0c-46b6-4e5b-8dc1-9023a805f465    1604    EquestiranMAT -CRYSTAL TROPHY   \N      f       \N      210     f       210
de74eef9-245c-488e-98d0-08f20c7ad090    1176    FarrierMAT -ACR 430 SIZE 00     \N      f       \N      289.75  f       289.75
6c6a5006-034e-4d80-a40e-e7231870fded    1175    FarrierMAT -ACR 430 SIZE 000    \N      f       \N      320.25  f       320.25
94cb1070-4f4e-437c-8ae2-51c23609ce86    1157    FarrierMAT -ACR 430 SIZE: 1     \N      f       \N      307.625 f       307.63
b72c965e-bd4a-493b-a472-a39269f15ae3    1158    FarrierMAT -ACR 430 SIZE: 2     \N      f       \N      305.786 f       305.79
bf104fcc-5a0a-4719-899a-ecbee668875b    1159    FarrierMAT -ACR 430 SIZE: 3     \N      f       \N      313.5825        f       313.5825
15324ebf-848b-4937-a860-40499f647b04    1160    FarrierMAT -ACR 430 SIZE: 4     \N      f       \N      325.5625        f       325.565
972632ad-94bd-4855-9b39-2368e2d58aa2    1171    FarrierMAT -ACR 800 SIZE 0      \N      f       \N      \N      f       262.5
2dff7bd2-c36b-444d-9e53-dea10c624247    1170    FarrierMAT -ACR 800 SIZE 00     \N      f       \N      262.5   f       262.5
8d5bb7e1-c4ed-4cfb-aa2b-2152aeb4f431    1172    FarrierMAT -ACR 800 SIZE 1      \N      f       \N      250     f       250
86bbb1fc-c7fe-4029-bbab-3c35b50f3286    1173    FarrierMAT -ACR 800 SIZE 2      \N      f       \N      \N      f       273
9f4e9620-0799-4c66-a775-ad3184442c53    1174    FarrierMAT -ACR 800 SIZE 3      \N      f       \N      260     f       260
5718596f-7bb9-4c94-9d92-6a54c6b0e555    849     FarrierMAT -ACR ALUMINUM HORSE PLATE 4 FRONT    \N      f       \N      11.3    f       11.3
a19d5b4f-7761-4128-a279-a3f159e18518    863     FarrierMAT -ACR EGG BAR ( 2 CLIPS ) SIZE 2      \N      f       \N      11.3    f       11.3
b777e2ca-022b-494e-ab7a-b8ce748ef1c1    797     FarrierMAT -ACR EGG BAR SHOES - NO. 3   \N      f       \N      11.3    f       11.3
c418cc26-435e-4693-9dbe-0c6790474c4a    862     FarrierMAT -ACR FRONT ( 3 CLIPS ) SIZE 3        \N      f       \N      11.3    f       11.3
b2e467ee-aa61-426e-8e0a-0c7b8d441c52    969     FarrierMAT -ACR SHOES SIZE NO. 000M     \N      f       \N      290     f       290
94531b35-c7b8-4b96-92ff-3cb2dcb67102    970     FarrierMAT -ACR SHOES SIZE NO. 04B      \N      f       \N      290     f       290
93e67fa3-4e57-4313-834b-b38f484b8317    971     FarrierMAT -ACR SHOES SIZE NO. 5        \N      f       \N      290     f       290
c75a3310-ed2c-4033-97a4-806a7fd883d3    905     FarrierMAT -ALUMINUM SHOE 1 CLIP BACK SIZE 1    \N      f       \N      11.13   f       11.13
bbab2df4-6563-4ade-8caa-4383eb0d2348    900     FarrierMAT -ALUMINUM SHOE 1 CLIP FRONT SIZE 0   \N      f       \N      11.13   f       11.13
4c145154-7c0a-47a1-abb3-d4772d473ec7    901     FarrierMAT -ALUMINUM SHOE 2 CLIP BACK SIZE 0C   \N      f       \N      11.13   f       11.13
695e727a-642d-43f5-a857-115bf30618c6    1006    FarrierMAT -APPLE HORSE SHOE WS-S4F     \N      f       \N      10      f       10
be172659-f2e4-4c0d-afba-f515161afe68    993     FarrierMAT -APPLE WS3F  \N      f       \N      10      f       10
745cd1fa-f967-4bbf-ab3f-3cec0c77979d    996     FarrierMAT -APPLE WS4F  \N      f       \N      10      f       10
59269579-b4e5-4316-84dd-89fa3d38f72a    866     FarrierMAT -BAKER 6 HIND 51/4X51/8X51/16        \N      f       \N      \N      f       30
6f2abd4e-4050-45e3-857d-e65c3feddef2    823     FarrierMAT -BAKER SHOE BACK 3   \N      f       \N      10      f       10
96d1a770-d185-4a19-bf3e-ff713d1924da    824     FarrierMAT -BAKER SHOE BACK 4   \N      f       \N      10      f       10
268e9efb-59f7-42e5-9416-639798b61d5c    825     FarrierMAT -BAKER SHOE BACK 4C  \N      f       \N      10      f       10
871d59eb-ac4c-49f1-a162-14642ecb94d1    826     FarrierMAT -BAKER SHOE BACK 5   \N      f       \N      10      f       10
c5c6161c-ccce-4791-ab68-829223f85a26    827     FarrierMAT -BAKER SHOE FRONT 3 FORE     \N      f       \N      10      f       10
05b072f0-fdfb-4dcf-8988-bba8ae5202a9    828     FarrierMAT -BAKER SHOE FRONT 4  \N      f       \N      10      f       10
687f0432-2e33-4be1-a3d0-dbd7962d71e3    829     FarrierMAT -BAKER SHOE FRONT 5 FORE     \N      f       \N      10      f       10
449d20f8-3935-4445-bee1-841a962d7a9f    830     FarrierMAT -BAKER SHOE FRONT 6C \N      f       \N      10      f       10
b0b21f64-e756-4d0c-8087-5af9d61a959a    1023    FarrierMAT -BLS BAR EGG TYPE SIZE:10 / 6 1/2    \N      f       \N      10      f       10
1f2bd922-d8e1-480c-9e41-7787693f679b    1063    FarrierMAT -BLS BAR SHOES HEART SIZE 3 (4 3/4)  \N      f       \N      \N      f       24.75
fda92728-8efc-4a59-a9de-0edea169d197    1067    FarrierMAT -BLS BAR SHOES SIZE 0 HEART BAR      \N      f       \N      10      f       10
fddae1e0-5138-4902-83ce-4dade7a33786    1062    FarrierMAT -BLS BAR SHOES STRAIGHT SIZE 3 (4 3/4)       \N      f       \N      10      f       10
74bb7c89-9dae-44eb-af56-879b06860788    1022    FarrierMAT -BLS BAR SHOSE HEART BAR SIZE:9      \N      f       \N      10      f       10
53469327-8b1c-48e3-8093-c9fcb383ce2c    1021    FarrierMAT -BLS BAR SHOSE STRAIGHT TYPE SIZE:10 / 6 1/2 \N      f       \N      10      f       10
46a34252-3bcd-497a-93ff-ac940e95583d    1029    FarrierMAT -BLS EGG BAR SIZE 9 / 6 1/4  \N      f       \N      10      f       10
47ac47d3-d10d-4814-bc99-00cfca9ff1e4    1024    FarrierMAT -BLS HEART BAR SIZE:10       \N      f       \N      10      f       10
d80b53e7-e9bc-403b-af13-4663d3a0a446    1026    FarrierMAT -BLS STRAIGH BAR SIZE:8 / 6  \N      f       \N      10      f       10
cd766c54-2067-44c4-968b-17a9efc092ae    1025    FarrierMAT -BLS STRAIGH BAR SIZE:9 / 6 1/4      \N      f       \N      10      f       10
33445a5f-db84-446c-a231-2910eaced835    1059    FarrierMAT -BLS STRAIGHT LINE SHOES SIZE 7      \N      f       \N      10      f       10
52d34719-0bb7-4ed4-9bdd-14909118907b    924     FarrierMAT -BORAX POWDER        \N      f       \N      85      f       85
7cb82a1b-dc80-4776-bc57-57b36613cab4    2480    FarrierMAT -BOSCH HAND GRINDER 4.5"     \N      f       \N      \N      f       265
b267dce7-1bb9-4020-bb2f-ad3b977ce34f    967     FarrierMAT -BROKESLANE 6        \N      f       \N      10      f       10
001a8997-a7fa-400c-bcb9-dd93757e8a77    851     FarrierMAT -BROOKS LANE ALUMINUM PLATE 4 F      \N      f       \N      \N      f       35
a88ea7f9-af66-4ccc-b1e5-01363172ecaf    2594    FarrierMAT -Barshoe Inserts (Welding):• Size 1  \N      f       \N      12      f       12
e3a449a9-b71e-477b-8870-e31c269d76aa    2595    FarrierMAT -Barshoe Inserts (Welding):• Size 2  \N      f       \N      12      f       12
ef9c1afd-369f-47a7-952e-3c9eaccde368    2597    FarrierMAT -Barshoe Inserts (Welding):• Size 4  \N      f       \N      12      f       12
3200a854-d036-4e05-9dd8-0445fcb9a8c5    2596    FarrierMAT -Barshoe Inserts (Welding):• Size3   \N      f       \N      12      f       12
2c4b0d7c-d635-4cb3-8654-b8add4b5a37a    1131    FarrierMAT -Bloom Farrier Tongs 8mm     \N      f       \N      237.5   f       237.5
bdc6e921-3b0f-4adb-90b2-314ca9b4d86e    1130    FarrierMAT -Bloom Fore Punch Wood       \N      f       \N      \N      f       451.5
fabd33f8-e574-4413-89f4-96be645c4f73    2136    FarrierMAT -Bloom Forge Regular Knife LH/RH     \N      f       \N      \N      f       180
85776909-131f-411c-bffb-a36b145d1c76    1129    FarrierMAT -Bloom Pritchel Long \N      f       \N      179.55  f       179.55
e25fc10f-123f-46cd-9399-eb756f5986bc    947     FarrierMAT -CAP HORSE SIZE 0    \N      f       \N      10      f       10
6092b29b-2c6b-464f-bedc-ac58263d7e45    948     FarrierMAT -CAP HORSE SIZE 1    \N      f       \N      10      f       10
7d1e4d3f-09fb-4d90-a8ce-a10d05a946ed    950     FarrierMAT -CAP HORSE SIZE 2    \N      f       \N      10      f       10
afb49435-970c-4f96-ab70-8ac908987a87    949     FarrierMAT -CAP HORSE SIZE 3    \N      f       \N      10      f       10
bda25e8a-739d-4d6b-8ed4-89654b5c041a    813     FarrierMAT -CLEANING HOOK       \N      f       \N      12.5    f       12.5
3f652cb7-ad1d-4444-b13e-74452a6fb7a0    831     FarrierMAT -CLIIPPED SHOE BACK 5C       \N      f       \N      10      f       10
28efbc6f-150a-466c-a868-e7aeb4b748ba    832     FarrierMAT -CLIIPPED SHOE BACK 5D       \N      f       \N      10      f       10
d83d721f-d2c4-4bf2-bf1d-ffdcf6e05646    833     FarrierMAT -CLIIPPED SHOE BACK 6        \N      f       \N      10      f       10
bddddb6a-937a-49a6-aa8e-5997e285de57    860     FarrierMAT -CLIIPPED SHOE BACK 6C       \N      f       \N      \N      f       32.5
3b3dd615-5a8d-467f-bfdf-03f263431b5d    834     FarrierMAT -CLIIPPED SHOE BACK 7        \N      f       \N      10      f       10
5bfea263-2411-4d34-9c2f-78c0f9e6166b    835     FarrierMAT -CLIIPPED SHOE FRONT 5C      \N      f       \N      10      f       10
fb5784e0-1738-4f84-985f-5a9157a430a3    836     FarrierMAT -CLIIPPED SHOE FRONT 6       \N      f       \N      10      f       10
aecc65e9-19c5-4438-9743-88a7d1943540    837     FarrierMAT -CLIIPPED SHOE FRONT 7       \N      f       \N      10      f       10
f40e75c8-ce1f-42e9-8343-300b89ff57d4    1075    FarrierMAT -CLINCH CUTTER DIAMOND C7    \N      f       \N      94.5    f       94.5
25f66135-b826-4438-a8f4-d2b6070d7701    1074    FarrierMAT -CLINCH GROOVER DOUBLE S     \N      f       \N      172.5   f       172.5
ec7f86d9-0db3-4556-a9d2-69475d635d6e    838     FarrierMAT -CLIPPED SHOE BACK 3 \N      f       \N      10      f       10
fd6f9c59-17af-4f96-a119-68d1f4d043d0    814     FarrierMAT -CLIPPER BLADE       \N      f       \N      125.25  f       125.25
6236ce6b-80cb-40fd-bd36-64932078877d    2481    FarrierMAT -CUTTING DISC 4.5 X 1MM      \N      f       \N      4       f       4
d65af874-d7f5-47a4-8abf-fb45a4204a94    2151    FarrierMAT -Copper Rivets 12X3/4        \N      f       \N      109     f       109
0c64b16c-124b-429c-9076-9a59d0538a66    2149    FarrierMAT -Copper Sulpate KG   \N      f       \N      99      f       99
055f3280-aa63-42bd-aa25-4c55f9d8a4c2    2139    FarrierMAT -Cross Pein Hammer 2LB FF    \N      f       \N      \N      f       1420
9f097663-f062-4af7-8b91-eb5f010cc74d    973     FarrierMAT -DARLIC CUFF \N      f       \N      32.5    f       32.5
fd62ec8e-46ed-4a04-a69e-6450a992e105    1161    FarrierMAT -DIAMOND LEATHER PADS WEDGED LARGE   \N      f       \N      78.75   f       78.75
bac0e999-dd16-43cd-8c01-1c603d0a4197    1162    FarrierMAT -DIAMOND MIXING TIPS FOR VETTEC 210 12/PKT   \N      f       \N      57.75   f       57.75
5d6fd93a-0476-4a29-bddd-972761c40994    2475    FarrierMAT -DIAMOND NAIL CUTTER N10 CLASSIC     \N      f       \N      \N      f       299
daf6cf97-d51f-45dc-aac7-9ca4ee36d948    815     FarrierMAT -DRILL BIT   \N      f       \N      10      f       10
8286b472-991b-43d9-9761-a8092d3c2e6b    2598    FarrierMAT -Diamond Frog Dressing       \N      f       \N      1080    f       1080
13459601-dcd3-4f95-8a76-90a63e6ad1b0    1135    FarrierMAT -Diamond Shoe Puller \N      f       \N      \N      f       85
7bc35de7-a804-43a8-9604-db4af5ff3727    2603    FarrierMAT -Double S Loop Knife \N      f       \N      160     f       160
5f624439-f507-44f5-9524-6d389ea3f717    1069    FarrierMAT -Double-S Knive (Left/Right) \N      f       \N      \N      f       29.25
03bde132-1d3b-4725-818d-41bbd39dbffa    2137    FarrierMAT -Dusky Forge Loop Knife      \N      f       \N      \N      f       935
0a199352-3a00-42a8-9bd4-8745bb1240e4    2140    FarrierMAT -Duval Pad Cutter    \N      f       \N      \N      f       1910
c8a1f669-2b01-4db2-ae01-12e900a48128    1052    FarrierMAT -E2 MUSTAD LIBERTY NAILS 24 X 250    \N      f       \N      68      f       68
22b733b1-ac6e-42ea-9bf0-801e10ea5fe0    1053    FarrierMAT -E3 MUSTAD LIBERTY NAILS 24 X 250    \N      f       \N      68      f       68
11672301-0b1a-43de-a6c0-b0bda4f9b450    896     FarrierMAT -EASY WALKER PLASTIC SHOE    \N      f       \N      25      f       25
7c096ed2-a010-43cf-a2f9-61f2e7a7af43    1060    FarrierMAT -EGG BAR SHOES SIZE 2        \N      f       \N      10      f       10
8505d78b-d430-41a9-835e-e60b73bf0309    961     FarrierMAT -EGG BAR SHOES SIZE 4        \N      f       \N      10      f       10
877d04ad-ed23-429f-9116-683a06c1658d    1181    FarrierMAT -EQUILOX BLACK 14 OZ \N      f       \N      390     f       390
f3d89049-4695-4d2f-9ef2-5c083d8c0ee7    2485    FarrierMAT -EQUILOX HOOF SUPPORT IMPRESSION BLUE KIT    \N      f       \N      575     f       575
39444ecf-430e-4956-8af0-a055ab31c5a1    2484    FarrierMAT -EQUILOX HOOF SUPPORT IMPRESSION PINK KIT    \N      f       \N      575     f       575
37897d5c-9879-4fe9-ba5d-cf717b49ab32    1182    FarrierMAT -EQUILOX TAN 14 OZ   \N      f       \N      \N      f       390
a3fe1851-a9f8-449a-903e-0d52e302adf8    2588    FarrierMAT -Equilox Dispensing Gun      \N      f       \N      599     f       599
c657dcfc-98ca-4445-9a08-d8477854b2d5    1012    FarrierMAT -FERSA CHEVAL HOR SHOE 16X08 DR      \N      f       \N      10      f       10
604d6099-088d-458e-86c3-8fbeb80338b5    1011    FarrierMAT -FERSA CHEVAL HOR SHOE 18X07B        \N      f       \N      10      f       10
1bfbee81-3741-44ab-a494-1533eef57624    2476    FarrierMAT -FF DRIVE HAMMER 14 OZ       \N      f       \N      \N      f       1300
75b3ef1d-5f8a-4622-a8a6-b4a8baddb617    2482    FarrierMAT -FLAP DISC 4.5       \N      f       \N      11      f       11
fd1ba868-3c0b-462b-b6dd-962e99f3b1e2    839     FarrierMAT -FOOT SCALING        \N      f       \N      15      f       15
e15fb4dc-981a-4272-9898-53c621fd11c8    2479    FarrierMAT -FPD ROUND HOOF TESTER 13"   \N      f       \N      \N      f       199
22c7cd74-01cb-48e2-9654-50e87cd9ee17    1117    FarrierMAT -FULLERING HAMMER    \N      f       \N      372.25  f       372.25
e192e994-3453-48f8-87c5-373c0211b345    1118    FarrierMAT -FULLERING HAMMER - SPARE HANDLE     \N      f       \N      52.5    f       52.5
0fc04bb3-2643-4385-99e3-b0ec0abb5682    1007    FarrierMAT -FUTHURE SIZE 2 HIND \N      f       \N      10      f       10
fd98b18e-8311-45b9-bbe9-4acf5d437af9    1005    FarrierMAT -FUTURE SHOE 3 HIND  \N      f       \N      10      f       10
10ca7c0d-efd2-4fee-a0cb-63330d39c107    2473    FarrierMAT -GE CURVED JAW CLINCHER      \N      f       \N      \N      f       990
2ae511de-6a50-43d2-b5ee-8a05db2df728    805     FarrierMAT -GE HALF ROUND NIPPER        \N      f       \N      \N      f       1363.95
9bfdcb81-4551-45ef-804b-ba4ff1689a0b    2474    FarrierMAT -GE LOW CURVED CLINCHER      \N      f       \N      \N      f       990
3ce25b9f-a874-4824-933f-f18938a6820d    1132    FarrierMAT -GE Nipper 14" Easy  \N      f       \N      \N      f       1290
a259515a-5d92-4cca-bcce-34b03ced4ff3    1165    FarrierMAT -GLU U SHOE 1F       \N      f       \N      \N      f       208.95
794ccf0c-452e-41a4-82aa-8aedac3178b5    1166    FarrierMAT -GLU U SHOE 3F       \N      f       \N      199     f       199
c72b8745-f637-4bca-b377-0e44523960ed    1016    FarrierMAT -GRINDING BELT       \N      f       \N      76.87571429     f       76.87571428571428
65a4d59d-b414-455e-b4f0-17b611988cce    903     FarrierMAT -GUE PARD ALUMINUM SHOE FRONT SIZE 28        \N      f       \N      11.13   f       11.13
f2f70116-6f3d-4db9-85c8-bf8a7b3e14f5    1116    FarrierMAT -HAMMER - SPARE HANDLE       \N      f       \N      78.75   f       78.75
a04416cc-9e7c-4c35-8dc5-82aa5f00b7cc    952     FarrierMAT -HEART BAR SHOE SIZE 7W      \N      f       \N      10      f       10
21a94cc7-65a3-49d4-bdc2-5d543fdb5848    806     FarrierMAT -HEAVY DUTY REVOLVING PLIER  \N      f       \N      36.5    f       36.5
c4ef781e-9262-4c7a-a8c2-f71269d387e0    807     FarrierMAT -HELLERS LEGEND RASP \N      f       \N      14.3    f       14.3
2b811aaf-9ab5-4d66-bb0d-4904fcfa436c    927     FarrierMAT -HOOF CUSHION PAD    \N      f       \N      16.51208333     f       16.512
65073882-306e-40f7-a40f-b39c364f4c13    925     FarrierMAT -HOOF MARVEL 946ML   \N      f       \N      \N      f       65
05ab0d42-9316-4c53-872e-4cb08cd70b01    808     FarrierMAT -HOOF OILBRUSH       \N      f       \N      8       f       8
4f67bb99-92eb-4ecb-8036-8ffd6037c31d    809     FarrierMAT -HOOF PICK/BRUSH     \N      f       \N      \N      f       8
65d9bad0-356b-4c97-9049-33e1039f454c    840     FarrierMAT -HOOF PLASTIC SHOE   \N      f       \N      14.5    f       14.5
e9b5dd33-4e9e-4ceb-908d-8abaf0a01bb4    811     FarrierMAT -HOOK OVER PORTABLE MANGER   \N      f       \N      4.5     f       4.5
39df1740-d051-4577-92da-4848008c8e9c    979     FarrierMAT -HORSE SHOE (OLD) SIZE 1B    \N      f       \N      10      f       10
5ed11e1b-653a-440f-bd24-c3cdf77b343e    978     FarrierMAT -HORSE SHOE (OLD) SIZE 1F    \N      f       \N      10      f       10
dec60505-2efb-4183-815a-4cdf08bb0d11    841     FarrierMAT -HORSE SHOE ALUMINUM W/ PLASTIC      \N      f       \N      20.5    f       20.5
baf24808-321f-4e18-b8e1-a6c77634442f    938     FarrierMAT -HORSE SHOE NO.0     \N      f       \N      10      f       10
491bfec1-6dab-4aea-8424-ff57f8d877e6    937     FarrierMAT -HORSE SHOE NO.1     \N      f       \N      10      f       10
0926cecc-cb8b-4b0f-9855-8a0a12b08d76    941     FarrierMAT -HORSE SHOE SIZE KB-00       \N      f       \N      10      f       10
9f67576c-168a-48b4-a723-eb53dea1872b    980     FarrierMAT -HORSE SHOES SIZE 3X0R BACK  \N      f       \N      10      f       10
ff9d93c5-9726-4df5-b286-f095d783c8c6    875     FarrierMAT -HORSE SHOOF TREATMENT       \N      f       \N      18.75   f       18.75
e9ea91f8-6f74-4069-93d2-8db5e62c78d8    2592    FarrierMAT -Hoof Buffer Drill Attachment        \N      f       \N      355     f       355
34aee688-0d99-4a48-a516-c1164f8d4373    2593    FarrierMAT -Hoof Buffer Replacement Belts       \N      f       \N      13      f       13
b98ed21e-0acf-4797-8386-ca7620677639    2148    FarrierMAT -Hoof Support Impression Kit \N      f       \N      \N      f       575
6147e950-0ba6-4135-bbc0-cfe96063f724    1127    FarrierMAT -JB Hot Fit Tong     \N      f       \N      228     f       228
05dfbdc8-6b5c-4818-adba-9496555e382c    1055    FarrierMAT -JC 0 MUSTAD LIBERTY NAILS 12 X 250  \N      f       \N      68      f       68
1ca748c1-0cbf-4e73-b24f-e6c4677c3dbe    864     FarrierMAT -JUMPING SHOES FRONT ( 3 CLIPS ) SIZE 3      \N      f       \N      10      f       10
c643829e-4c77-4ccb-9621-f3d673243cb1    865     FarrierMAT -JUMPING SHOES FRONT ( 3 CLIPS ) SIZE 4      \N      f       \N      10      f       10
0f0a5c2f-33fa-4b4d-905f-865ecfbeb3d6    933     FarrierMAT -KB ALUMINUM SHOE SIZE 00    \N      f       \N      11.13   f       11.13
d3e62608-e2e7-4f82-91a7-1cc38832ce19    935     FarrierMAT -KB ALUMINUM SHOE SIZE R3    \N      f       \N      11.13   f       11.13
75b5bfad-cb76-4a1a-bc60-538ed4e4dcdc    934     FarrierMAT -KB ALUMINUM SHOE SIZE R4    \N      f       \N      11.13   f       11.13
3b5d0099-47f0-495b-a7df-6c0c3f8f9ce0    1003    FarrierMAT -KERCHAERT 6 FRONT 30        \N      f       \N      10      f       10
b429ed84-e6b6-4c19-ad64-0a124fc14baa    889     FarrierMAT -KERCHAERT ALUMINUM BACK SIZE 000    \N      f       \N      11.126  f       11.13
eeadc55f-2a19-4114-ad26-63e5c0ce188d    842     FarrierMAT -KERCHAERT ALUMINUM PLATE 5FRONT     \N      f       \N      39.5    f       39.5
0a21c3de-73d4-4821-88ff-dccde985cedf    843     FarrierMAT -KERCHAERT ALUMINUM PLATE 6 FRONT    \N      f       \N      11.13   f       11.13
80c682ac-38f5-4df3-acdc-bef88e09c465    844     FarrierMAT -KERCHAERT ALUMINUM PLATE 7FRONT     \N      f       \N      11.13   f       11.13
e6b16a00-ad5e-4d9e-9c48-13885f3fdbc1    904     FarrierMAT -KERCHAERT ALUMINUM SHOE 2 CLIP BACK \N      f       \N      11.13   f       11.13
8395c462-0e76-4854-af82-fea217db7ca4    902     FarrierMAT -KERCHAERT ALUMINUM SHOE 2 CLIP BACK SIZE 0  \N      f       \N      11.13   f       11.13
af4910b6-a12c-46cb-8817-7680440a71f7    906     FarrierMAT -KERCHAERT ALUMINUM SHOE 2 CLIP BACK SIZE 2  \N      f       \N      11.13   f       11.13
f94bbe3b-b488-43c4-9063-6e41a95d9052    907     FarrierMAT -KERCHAERT ALUMINUM SHOE FAST-BREAK SIZE 6   \N      f       \N      11.13   f       11.13
d5ebbc1c-995f-4d46-b581-61c76f7f393f    939     FarrierMAT -KERCHAERT ALUMINUM SHOE SIZE NO. 00 \N      f       \N      11.126  f       11.13
265938b9-128c-4b76-971e-957d9858998d    936     FarrierMAT -KERCHAERT ALUMINUM SHOE SIZE NO. 2  \N      f       \N      11.12588235     f       11.125882352941176
613881be-92e9-41dc-93fd-705255ee0f45    898     FarrierMAT -KERCHAERT RACING PLATE SIZE 4F      \N      f       \N      11.13   f       11.13
d6785fcc-0dd9-41b9-8e5c-0f1044df6f39    1094    FarrierMAT -KERCKHAERT DF 0 FRONT QUARTER CLIP  \N      f       \N      12.75   f       12.75
db3cea13-6cd3-4ca3-8ff8-8e1256be99f0    1093    FarrierMAT -KERCKHAERT DF 0 FRONT TOE CLIP      \N      f       \N      12.4246 f       12.5
bda8661e-c821-455a-994d-84545d69ee73    1095    FarrierMAT -KERCKHAERT DF 0 HIND CLIP   \N      f       \N      12.02986842     f       12.03
511c9c12-dd08-4509-a39e-7028d4f5c3f7    1090    FarrierMAT -KERCKHAERT DF 00 FRONT TOE CLIP     \N      f       \N      12.6    f       12.6
a91abff3-3255-4de1-a8ef-aa934809e4f0    1092    FarrierMAT -KERCKHAERT DF 00 HIND CLIP  \N      f       \N      11.7876087      f       11.787666666666667
c7f26f02-f8dc-4434-b54b-3d0193120b35    1091    FarrierMAT -KERCKHAERT DF 00 QUARTER CLIP       \N      f       \N      12.696375       f       12.75
52df842c-b1b0-4061-afe6-579f790c7355    1097    FarrierMAT -KERCKHAERT DF 1 FRONT QUARTER CLIP  \N      f       \N      13.54169811     f       13.75
08f85738-855e-4199-9406-dbe7a1ca8363    1096    FarrierMAT -KERCKHAERT DF 1 FRONT TOE CLIP      \N      f       \N      12.44577778     f       12.5
073b9b3d-147a-4b18-9209-b6b67575f988    1098    FarrierMAT -KERCKHAERT DF 1 HIND CLIP   \N      f       \N      12.31578125     f       12.25
46c72ec3-17b1-482b-8f01-ed7b690324f9    1100    FarrierMAT -KERCKHAERT DF 2 FRONT QUARTER CLIP  \N      f       \N      13.75   f       13.75
cb17ad77-95f3-439d-ae70-d5f90c78da8f    1099    FarrierMAT -KERCKHAERT DF 2 FRONT TOE CLIP      \N      f       \N      10.68460784     f       12.5
205c93ac-6a2b-4bc3-99d4-69e26f538821    1101    FarrierMAT -KERCKHAERT DF 2 HIND CLIP   \N      f       \N      11.9254 f       12.086
0d838ae5-d260-4628-9e21-e0507cacc9ee    1103    FarrierMAT -KERCKHAERT DF 3 FRONT QUARTER CLIP  \N      f       \N      14.5    f       14.5
aaa2b60b-c5e3-4043-b9a4-5f6b84a61197    1102    FarrierMAT -KERCKHAERT DF 3 FRONT TOE CLIP      \N      f       \N      12.73427273     f       13
d0dbde8c-de61-43cf-afc0-ac4782712209    1104    FarrierMAT -KERCKHAERT DF 3 HIND CLIP   \N      f       \N      12.66084211     f       12.660666666666668
ac0f6988-d167-4d92-97b0-3bc556f6351b    1106    FarrierMAT -KERCKHAERT DF 4 FRONT QUARTER CLIP  \N      f       \N      14.26253731     f       14.262666666666666
b5e0cd35-57b1-492f-9f7e-e6454692efaa    1105    FarrierMAT -KERCKHAERT DF 4 FRONT TOE CLIP      \N      f       \N      13.24360656     f       13.243666666666668
3a92fdb8-bb86-499c-9a9e-b8fb6e050a6d    1107    FarrierMAT -KERCKHAERT DF 4 HIND CLIP   \N      f       \N      13.24380282     f       13.2439
764c7f5f-b5b3-4d2c-af68-0ca089d348a0    2586    FarrierMAT -KERCKHAERT DF 5 FRONT QUARTER CLIP  \N      f       \N      16      f       16
2bf8375e-d534-4b31-9d3d-0998fdd1b7cd    2585    FarrierMAT -KERCKHAERT DF 5 FRONT TOE CLIP      \N      f       \N      15.5    f       15.5
d99ce3d8-da3d-41cb-8aa9-6710722a0366    2587    FarrierMAT -KERCKHAERT DF 5 HIND CLIP   \N      f       \N      15.5    f       15.5
52d42bc1-e7cb-4d7a-8c7a-77fa8b45bb7d    1108    FarrierMAT -KERCKHAERT SIZE 00 TOE CLIP \N      f       \N      12.72130435     f       12.72125
d9620330-6280-4946-a0fa-38c2239d7867    801     FarrierMAT -KNIFE DOUBLE S      \N      f       \N      \N      f       135
439462cd-c07e-4971-a6ff-991fe6a594e9    1076    FarrierMAT -KULP SPREADER ASYMMETRICAL  \N      f       \N      231     f       231
22e5c20c-fe96-4e8c-b550-efea171b4353    2141    FarrierMAT -Knife Sharpener     \N      f       \N      \N      f       140
dffe1f37-6ed6-451e-8791-8e3618742c63    1123    FarrierMAT -L.B. BACK 2 CLIPS - NO. 2 X 0       \N      f       \N      10      f       10
2146cd46-78d9-4e3f-bde6-160714de43db    910     FarrierMAT -LB METAL SHOE 1 CLIP SIZE 3X0       \N      f       \N      10      f       10
c25046c7-439b-4063-beb2-9d2b46766ea1    912     FarrierMAT -LB METAL SHOE 2 CLIP BACK SIZE 4X0  \N      f       \N      10      f       10
00a7a9cc-6f47-4175-9e2d-1910014e680e    893     FarrierMAT -LB METAL SHOE 2CLIP BACK SIZE 3X0   \N      f       \N      10      f       10
b4ae4ef6-75f6-42bd-9f2d-e5d27d548973    816     FarrierMAT -LEATHER PADS REGULAR        \N      f       \N      23.19789474     f       23.198
dfa6aa45-3d4f-47d8-90cf-0a76176a603e    846     FarrierMAT -LEATHER ROLL        \N      f       \N      115     f       115
38dda7f6-7df8-4aa0-b565-3dafcf85c243    2472    FarrierMAT -LIBERTY NAILS E10 DRAFT XL 100/BOX  \N      f       \N      63.66666667     f       63.67
bb219203-c89e-4c27-948d-e992a2e57218    1186    FarrierMAT -LIBERTY NAILS ESL4 (51MM) 250/BOX   \N      f       \N      70.035  f       69
924aea77-d04b-406d-9eca-b2a6b5b23542    1187    FarrierMAT -LIBERTY NAILS HYBRID 4 – 250/BOX    \N      f       \N      73.16363636     f       73.38333333333334
063f5006-f430-484c-ad07-001b2c266253    1188    FarrierMAT -LIBERTY NAILS HYBRID 5 – 250/BOX    \N      f       \N      \N      f       80.85
a052fb33-ef56-4607-b5ea-455867f8a942    847     FarrierMAT -LOCAL RASP FARRIER  \N      f       \N      15.5    f       15.5
cc4b1e47-05d5-4834-a28b-7d795023fb2c    920     FarrierMAT -LUWEX HOOF PAD      \N      f       \N      43.17521739     f       43.175
adcf7d08-4c67-4e35-8eef-0f592f3820b6    922     FarrierMAT -LUWEX SOFT GLUE     \N      f       \N      21.3575 f       21.3575
a182f682-baee-4147-8f0f-403b955a5796    984     FarrierMAT -MADDOX JC00 \N      f       \N      68      f       68
2cb506e6-b14d-45e3-bd77-2611d3d9f8eb    923     FarrierMAT -MAGIC CUSHION       \N      f       \N      35.75   f       35.75
82b9f665-9400-4669-a001-ee0a0601687b    812     FarrierMAT -MANE PLAITING RUBBER BAND   \N      f       \N      8       f       8
4330dd21-d352-405a-b1d3-bfb5b983c6b0    932     FarrierMAT -METAL RACING PLATE 1 CLIP SIZE 25   \N      f       \N      11.13   f       11.13
5cd98bb4-1c23-4ed5-867b-5b04453d27b4    895     FarrierMAT -METAL SHOE 2 CLIP BACK SIZE 2 (OLD) \N      f       \N      10      f       10
65418413-65fd-487d-b779-fd6a448397a0    909     FarrierMAT -METAL SHOE 2 CLIP BACK SIZE 3X0     \N      f       \N      10      f       10
191d51aa-c1ec-4b6e-99f5-afb0d5425e15    2766    FarrierMAT -METAL SHOE 2 CLIP BACK SIZE 3X0A    \N      f       \N      32.5    f       32.5
9e47971f-445f-4869-9951-5d9c68a89242    892     FarrierMAT -METAL SHOE 2 CLIP BACK SIZE 3X0L    \N      f       \N      10      f       10
ac08b971-8635-4785-93ba-c93a9ded83a1    891     FarrierMAT -METAL SHOE 2 CLIP BACK SIZE 3X0R    \N      f       \N      10      f       10
c7cc6b3a-31a5-4d2e-bd41-653f3fd9b96c    890     FarrierMAT -METAL SHOE 2 CLIP BACK SIZE 4       \N      f       \N      10      f       10
c38ec587-a16a-4557-a81a-a38e36dc1683    911     FarrierMAT -METAL SHOE 2 CLIP FRONT SIZE 1      \N      f       \N      10      f       10
d0b56795-fe59-4738-9b42-feb5b3fd3a52    1058    FarrierMAT -MUSTAD E-8 NAILS    \N      f       \N      \N      f       88.75
651fa24c-1323-4fde-a3f6-7c0e75b6be81    1010    FarrierMAT -MUSTAD LB 4X0H 22X8 \N      f       \N      10      f       10
e6da3fe6-0a49-4b57-b7c2-0d0f806b52a9    987     FarrierMAT -MUSTAD NAIL E5      \N      f       \N      68      f       68
9ec3b638-5ec6-444d-a7d8-b53691babfbb    986     FarrierMAT -MUSTAD NAIL E5 SLIM \N      f       \N      68      f       68
4af3a99b-c2e6-471e-a6be-1f67cf3df9af    985     FarrierMAT -MUSTAD NAIL E6      \N      f       \N      68      f       68
1e132dc7-238a-4e13-b07a-f5f664e13a4a    886     FarrierMAT -MUSTAD NAIL E6 8X500        \N      f       \N      68      f       68
e6957ebd-8b82-46ae-93af-dfff3825ad4d    885     FarrierMAT -MUSTAD NAIL E6 SLIM 8X250   \N      f       \N      68      f       68
4c7d3c39-1d1e-4b3f-9ae5-c16516eeb2ec    887     FarrierMAT -MUSTAD NAIL E7 12X250       \N      f       \N      68      f       68
a6465f35-429e-4c58-b673-36a0bf062fcb    888     FarrierMAT -MUSTAD NAIL E8 12X100       \N      f       \N      68      f       68
dc2b77bb-781f-4d1c-a26b-8514d9206731    1015    FarrierMAT -MUSTAD NAIL RN 4    \N      f       \N      68      f       68
307a2537-f18d-4273-b476-b2a92211a216    982     FarrierMAT -MUSTAD NAILS ASV2   \N      f       \N      68      f       68
64fa47d6-524c-4766-99a4-0a96da723fb1    981     FarrierMAT -MUSTAD NAILS JC00   \N      f       \N      68      f       68
bd7836ec-3353-4c03-a00d-fc53df19e550    966     FarrierMAT -MUSTAD NAVICULAR SIZE 1     \N      f       \N      10      f       10
b1cb62eb-46be-42bf-b764-d38ebee1b0f4    945     FarrierMAT -MUSTAD RACE 1       \N      f       \N      10      f       10
fa60abab-bbc1-4497-920e-bf65750abf01    946     FarrierMAT -MUSTAD RACE 2       \N      f       \N      10      f       10
045f89d7-c850-4db6-a831-752505acd120    944     FarrierMAT -MUSTAD SHOE KBR3    \N      f       \N      10      f       10
962fd9a5-7568-4ccc-9029-33caa8d2440f    943     FarrierMAT -MUSTAD SHOE KBR4    \N      f       \N      10      f       10
cb4b2778-9e66-4c45-a0ca-e20a9d1183e0    942     FarrierMAT -MUSTAD SHOE M 00R   \N      f       \N      10      f       10
d8275296-71d7-4d0e-852d-7b436ee1487b    963     FarrierMAT -MUSTAD WEDGE SIZE 0 \N      f       \N      10      f       10
f8533552-8959-450f-b997-6d103cbbed44    962     FarrierMAT -MUSTAD WEDGE SIZE 00        \N      f       \N      10      f       10
75af04ea-4e76-4d25-8554-0947da9739be    964     FarrierMAT -MUSTAD WEDGE SIZE 1 \N      f       \N      10      f       10
851417b0-4d97-4e96-af9f-a57500bff922    965     FarrierMAT -MUSTAD WEDGE SIZE 2 \N      f       \N      10      f       10
8d19c767-279b-4cbe-a125-aedb04635565    919     FarrierMAT -NBS ALUMINUM PLATE SIZE 00V \N      f       \N      11.12578947     f       11.125789473684211
bc6652fe-61a8-416b-ac5e-d12dc1d8cfd5    918     FarrierMAT -NBS ALUMINUM PLATE SIZE 1V  \N      f       \N      11.13   f       11.13
93bd64c5-2746-4bbe-919d-b844829cae51    917     FarrierMAT -NBS ALUMINUM PLATE SIZE 2V  \N      f       \N      11.12666667     f       11.13
be0d70e1-8dae-4523-be3b-2bcb7f758511    921     FarrierMAT -NBS ALUMINUM PLATE SIZE 3V  \N      f       \N      11.12711864     f       11.13
35eb7f3d-ff40-4516-a19b-6bf707b0ab12    861     FarrierMAT -NBS HORSE PLATE 0 F 1X20    \N      f       \N      10      f       10
303e0a19-cd61-429c-a0d0-89277ebfd945    2477    FarrierMAT -NC DRIVE HAMMER HANDLE      \N      f       \N      \N      f       49
871dac61-50a0-4bea-8dbb-bebe10d08990    1073    FarrierMAT -Nail Nipper \N      f       \N      139.5   f       139.5
25a4dc77-6080-4a55-92e1-72204610c12c    975     FarrierMAT -PASIC LB SIZE 2X0H 22X8     \N      f       \N      10      f       10
e0b6cb5b-529a-4d5a-8c57-fcc8988755e5    974     FarrierMAT -PASIC LB SIZE 3X0H  \N      f       \N      10      f       10
b859efc6-2830-427c-bd18-e2745c38dd96    897     FarrierMAT -PLASTIC PONY        \N      f       \N      \N      f       22.5
db878897-19dd-413e-aa26-9888c4f8a0fa    1180    FarrierMAT -PLASTIC WRAP WITH HANDLE    \N      f       \N      \N      f       40.95
b03867ef-c2d1-4f9f-9314-9d0bf1302dde    2589    FarrierMAT -Plastic Wrap (Cling Film)   \N      f       \N      23      f       23
6804fa0c-aa15-4b06-ae98-68539b93687b    955     FarrierMAT -REDIJAN 28 THDR     \N      f       \N      10      f       10
ffb4716a-8938-4d97-b75c-e34d79c403fd    956     FarrierMAT -REDIJAN 30L \N      f       \N      10      f       10
d8cb33c3-5865-4b34-988e-2944b02faf6c    960     FarrierMAT -REDIJAN R26L        \N      f       \N      10      f       10
8a4581b3-6289-438f-a67b-09c3ecd0fb3d    959     FarrierMAT -REDIJAN R27L        \N      f       \N      10      f       10
3567b44e-e4a6-404e-9562-318a7c60a26a    958     FarrierMAT -REDIJAN R28 \N      f       \N      10      f       10
e8c46f35-6786-4b10-8a72-65fc04115ad9    957     FarrierMAT -REDIJAN R29 \N      f       \N      10      f       10
586598d0-3fdd-44d1-a608-a678f4d57393    2138    FarrierMAT -Rasp Handle Diamond \N      f       \N      \N      f       35
9dbdcc94-399d-47e1-a26e-1312ff15035e    2590    FarrierMAT -Rounding Hammer  (Beanie)  2 lb     \N      f       \N      \N      f       \N
5fdf7357-b5e8-4608-b7e1-a8d42858ecff    1028    FarrierMAT -SBS EGG BAR SIZE 8 / 6      \N      f       \N      10      f       10
d841812f-abd1-4ba6-99b8-d908265bc24d    1018    FarrierMAT -SBS EGG TYPE SIZE :6 / 5 1/2        \N      f       \N      10      f       10
c4c192ef-1b63-4169-aec4-2b9da74bd8b3    1020    FarrierMAT -SBS EGG TYPE SIZE :7 / 5 3/4        \N      f       \N      10      f       10
332a8799-1212-473d-bac3-bda4826307e2    1027    FarrierMAT -SBS HEART TYPE SIZE :8 / 6  \N      f       \N      10      f       10
bc2801e2-ebab-44aa-9c17-2bb818c0aecc    1019    FarrierMAT -SBS STRAIGHT TYPE SIZE:7 / 5 3/4    \N      f       \N      10      f       10
b55ac88e-a4a1-412f-bc87-69e04d0b5f4d    1084    FarrierMAT -ST. CROIX ALUMINIUM QUARTER CLIP SIZE 0 HIND        \N      f       \N      11.1266 f       11.13
a3789c68-9757-438a-bf4a-853a617eec63    1083    FarrierMAT -ST. CROIX ALUMINIUM QUARTER CLIP SIZE 00 HIND       \N      f       \N      11.12724138     f       11.13
a6c741a9-4dbc-4f17-bc92-b2994739e8b0    1085    FarrierMAT -ST. CROIX ALUMINIUM QUARTER CLIP SIZE 1 HIND        \N      f       \N      11.12696429     f       11.13
6dceabd3-a967-47c2-a46b-fa5e16b0a737    1082    FarrierMAT -ST. CROIX ALUMINIUM QUARTER CLIP SIZE 2 FRONT       \N      f       \N      11.12679688     f       11.13
8fb0c614-d143-4a40-8017-d5f1cc646bc5    1086    FarrierMAT -ST. CROIX ALUMINIUM QUARTER CLIP SIZE 2 HIND        \N      f       \N      11.12585714     f       11.125857142857143
152ce8b5-62d7-4d60-8db9-fbe144cae0df    915     FarrierMAT -ST. CROIX FORGE ALUMINUM BACK SIZE 1H       \N      f       \N      11.13   f       11.13
c1147545-d8c1-467d-8888-4808a3ce1b93    916     FarrierMAT -ST. CROIX FORGE ALUMINUM BACK SIZE 2H       \N      f       \N      11.13   f       11.13
727316d6-5a60-48d4-ade6-f485df44aba8    914     FarrierMAT -ST. CROIX FORGE ALUMINUM FRONT SIZE 2F      \N      f       \N      11.13   f       11.13
27b90dac-c358-4fdf-a062-4ad207cc7a16    877     FarrierMAT -ST. CROIX FORGE CONCORDE SIZE 3-F   \N      f       \N      10      f       10
00f29baf-aa83-462a-8dc0-a6ed269e7ac1    880     FarrierMAT -ST. CROIX FORGE CONCORDE SIZE 4-F   \N      f       \N      10      f       10
e00ba2c1-2afd-43ef-9057-8c69a3571a1d    879     FarrierMAT -ST. CROIX FORGE CONCORDE SIZE 5-F   \N      f       \N      10      f       10
4e3978ba-016c-4d83-beec-de7856bc7e09    878     FarrierMAT -ST. CROIX FORGE CONCORDE SIZE 6-F   \N      f       \N      10      f       10
9b68f119-bc1d-4bd8-a92e-d5f3cf5ed9d7    881     FarrierMAT -ST. CROIX FORGE CONCORDE SIZE 7-F   \N      f       \N      10      f       10
262020ff-f6fb-473e-a634-44e21d3cd985    798     FarrierMAT -ST. CROIX FORGE STEEL BACK 2 CLIPS - NO. 4  \N      f       \N      32      f       32
0f33cd6e-c0fe-44ea-a298-cb65559e88b4    854     FarrierMAT -STEEL BAR HORSE PLATE 5 1/4 FRONT   \N      f       \N      10      f       10
ac575dcc-8f7f-477d-8fdc-d748bc54a168    855     FarrierMAT -STEEL BAR HORSE PLATE 5 3/4 FRONT   \N      f       \N      10      f       10
9dd7f29f-cb95-4d26-9fc6-2070f45a07e3    977     FarrierMAT -STEEL BAR SHOES     \N      f       \N      10      f       10
a4e5fcfe-e77f-461e-ba54-d7d5b4466db1    1065    FarrierMAT -STEEL BAR SHOES HEARTH SIZE 6 (5 1/2)       \N      f       \N      10      f       10
aad99a0b-fc08-4a12-b641-54924dee2ca1    1017    FarrierMAT -STEEL BAR SHOES SIZE:5 / 5 1/4      \N      f       \N      10      f       10
475ecc79-26d7-4ee3-90b5-6e9e08ca089e    1066    FarrierMAT -STEEL BAR SHOES STRAIGHT SIZE 4 (5) \N      f       \N      10      f       10
33a46acb-8c81-4b77-aaa8-ab452af07577    1064    FarrierMAT -STEEL BAR SHOES STRAIGHT SIZE 6 (5 1/2)     \N      f       \N      10      f       10
dfe3067e-84c2-4fce-b3ee-8d25f82c9421    1061    FarrierMAT -STEEL BARS SHOES SIZE 3 (4 3/4)     \N      f       \N      10      f       10
4607c854-5068-4a3a-8d15-eeba3a52adf1    926     FarrierMAT -STUD        \N      f       \N      4.66666667      f       4.66675
3e5c5f9c-ff24-49d7-894a-84d62fc9b1ca    931     FarrierMAT -SURGICAL SHOE PLATE SIZE 00F        \N      f       \N      12      f       12
7abadb10-4b0c-40a8-88af-c5454b86a73a    930     FarrierMAT -SURGICAL SHOE PLATE SIZE 1F \N      f       \N      12      f       12
a35ebfd3-8fb9-4123-9ed7-09879f4598b1    929     FarrierMAT -SURGICAL SHOE SIZE 2F       \N      f       \N      12      f       12
c1aae119-3998-49a2-b3c4-f8188088f56e    928     FarrierMAT -SURGICAL SHOE SIZE 3F       \N      f       \N      12      f       12
e24d9d81-8302-4a6b-919d-3804f1fc8d01    1141    FarrierMAT -Sell Crease nail Puller     \N      f       \N      730     f       730
e64bb777-5a35-4546-a85d-d242282a7fca    1042    FarrierMAT -St. Croix Aluminum 0 Size Quarter Clip      \N      f       \N      11.13   f       11.13
8296e2a5-c9a3-4a0d-a156-5158c6d0b430    1041    FarrierMAT -St. Croix Aluminum 00 Size Quarter Clip     \N      f       \N      11.13   f       11.13
50248cdc-12fa-4f5a-b08b-5a7ed0343f9e    1043    FarrierMAT -St. Croix Aluminum 1 Size Quarter Clip      \N      f       \N      11.13   f       11.13
701e740b-fe68-4dea-83cc-32ce09d11ffa    1032    FarrierMAT -St. Croix Steel 00 size Hind        \N      f       \N      10.65   f       10.65
3879d014-2000-4841-b121-752c928cfe22    1031    FarrierMAT -St. Croix Steel 00 size Quarter Clip        \N      f       \N      13.5    f       13.5
baa62f5a-7bc7-42f9-939b-dce9351a7400    1040    FarrierMAT -St. Croix Steel 3 size Hind \N      f       \N      14.5    f       14.5
656eb0de-123e-4920-b2bb-9168712c5857    1039    FarrierMAT -St. Croix Steel 3 size Quarter Clip \N      f       \N      11.98333333     f       11.983333333333333
f271dd49-926e-493d-8f58-ebe2de570d4c    1038    FarrierMAT -St. Croix Steel 3 size Toe Clip     \N      f       \N      11.7075 f       11.707666666666666
45687310-d672-4d0e-bde1-f43f9a5d7918    856     FarrierMAT -THORO BRED ALUMUNIM RACING PLATE 5 FRONT    \N      f       \N      11.13   f       11.13
9b163c89-b6df-438f-92d3-eb2b624bc2f6    899     FarrierMAT -THOROBRED ALUMINUM QUEENS/HIND SIZE 4 (X4)  \N      f       \N      11.13   f       11.13
7986ced3-0b4d-45af-ad30-4d5f4bdffd1a    1013    FarrierMAT -THOROBRED ALUMINUM QXH SIZE 4 (X4 BOX)      \N      f       \N      11.13   f       11.13
2ef5daeb-642c-4db1-ba9b-e444c1396e01    1014    FarrierMAT -THOROBRED ALUMINUM QXH SIZE 5 (X4 BOX)      \N      f       \N      11.13   f       11.13
4ed41f0a-e439-46c8-a5b4-d1863bf900c3    882     FarrierMAT -THOROBRED ALUMINUM SIZE 4F  \N      f       \N      11.12594595     f       11.125945945945945
ba7da0b9-552d-4adc-bbe0-5a30d46ec70e    883     FarrierMAT -THOROBRED ALUMINUM SIZE 5F  \N      f       \N      11.125625       f       11.125625
3e309eb7-08cf-4990-806f-f434333f48f1    884     FarrierMAT -THOROBRED ALUMINUM SIZE 6F  \N      f       \N      11.125625       f       11.125625
bb7eedfd-4a11-469d-8783-c93bc0711690    818     FarrierMAT -THOROBRED RACING PLATE( WRP SIZE 6F)        \N      f       \N      11.13   f       11.13
2e579433-359f-4f28-98fa-473256250f74    819     FarrierMAT -THOROBRED RACING PLATE(QUEENS SIZE 5 FRONT) \N      f       \N      11.13   f       11.13
6846337e-d173-4021-a8e3-5ca9e57c05fe    820     FarrierMAT -THOROBRED RACING PLATE(QUEENS SIZE 8 FRONT) \N      f       \N      11.13   f       11.13
a7a57cc2-bd1d-4c60-be7a-36f3c03b0b4e    822     FarrierMAT -THOROBRED RACING PLATE(WRD SIZE 7)  \N      f       \N      11.13   f       11.13
8b855f2b-d619-4510-b40c-fbecd0fc72aa    1077    FarrierMAT -THROUGHBRED RACING QUEEN XT PLATE ALUMINIUM 4 SIZE HIND     \N      f       \N      11.12789474     f       11.13
76ceb7eb-0dd9-4214-a75a-3d52fd35f136    1078    FarrierMAT -THROUGHBRED RACING QUEEN XT PLATE ALUMINIUM 5 SIZE HIND     \N      f       \N      11.125875       f       11.125875
0bd934d7-7332-4115-bc39-f600c9d0f5fa    1079    FarrierMAT -THROUGHBRED RACING QUEEN XT PLATE ALUMINIUM 6 SIZE HIND     \N      f       \N      11.125875       f       11.125875
d09d10d1-37e2-4b42-acfb-436f499c874f    1080    FarrierMAT -THROUGHBRED RACING QUEEN XT PLATE ALUMINIUM 7 SIZE HIND     \N      f       \N      11.12581818     f       11.125818181818182
e953ad95-92e4-4ce0-9117-464bbc4f37bd    1081    FarrierMAT -THROUGHBRED RACING QUEEN XT PLATE ALUMINIUM 8 SIZE HIND     \N      f       \N      11.12575        f       11.12575
5519c8d3-e53b-49b1-85b8-d1ed4692393d    857     FarrierMAT -TOPAZE ALUMINUM RACING PLATE 26 BACK        \N      f       \N      11.13   f       11.13
cffbc623-06ec-467d-9f09-591e9815dd93    992     FarrierMAT -TOPAZE SIZE 26 BACK \N      f       \N      10      f       10
8c55c16a-cdd5-45a3-8de9-9a7acb66832e    995     FarrierMAT -TOPAZE SIZE 26 F    \N      f       \N      10      f       10
550183e9-522f-4282-8775-424f9428de00    994     FarrierMAT -TOPAZE SIZE 27 BACK \N      f       \N      10      f       10
0acbeb7c-e0ca-4f30-9c40-b386a1d68d06    989     FarrierMAT -TOPAZE SIZE 28F     \N      f       \N      \N      f       45.5
49f24fb7-2585-4e7b-96b5-158bb0fe11cf    991     FarrierMAT -TOPAZE SIZE 29 BACK \N      f       \N      10      f       10
3151fa9f-6b90-4e0b-a2d6-274cd1f925ac    990     FarrierMAT -TOPAZE SIZE 30 BACK \N      f       \N      10      f       10
faa40ab6-abe0-486b-bb27-a08618b1f256    1044    FarrierMAT -Thoroughbred Racing Plate aluminum 4 Size Front     \N      f       \N      11.1265625      f       11.13
0da484a7-4ffe-440c-90b3-411318fab1c3    1045    FarrierMAT -Thoroughbred Racing Plate aluminum 4 Size Hind      \N      f       \N      11.126  f       11.126
a843bf87-1587-4206-a770-6c0529e626b7    1046    FarrierMAT -Thoroughbred Racing Plate aluminum 5 Size Front     \N      f       \N      11.12613636     f       11.13
20027fd9-6ae6-4ea3-9377-9e8123abb53d    1047    FarrierMAT -Thoroughbred Racing Plate aluminum 5 Size Hind      \N      f       \N      11.1258 f       11.1258
24f70941-594b-462f-bb63-43355dfa13ae    1048    FarrierMAT -Thoroughbred Racing Plate aluminum 6 Size Front     \N      f       \N      11.12641304     f       11.13
359f597d-5e48-4034-8345-995d1a27e376    1049    FarrierMAT -Thoroughbred Racing Plate aluminum 6 Size Hind      \N      f       \N      11.12632653     f       11.13
ea49f387-d4b1-45c3-886a-7418ef4037d5    1050    FarrierMAT -Thoroughbred Racing Plate aluminum 7 Size Front     \N      f       \N      11.4647 f       11.4647
da89819c-9886-43bd-9dd6-49305d66ece0    1051    FarrierMAT -Thoroughbred Racing Plate aluminum 7 Size Hind      \N      f       \N      13.78   f       13.78
536f9d1a-c4b6-47b0-8d5a-c2adb0e9c833    1139    FarrierMAT -Toeing Knife Diamond 280mm  \N      f       \N      \N      f       50.225
a0287433-89d5-4fc5-9005-c88ceccee856    2150    FarrierMAT -Tungsten Pin 5MM    \N      f       \N      \N      f       196
b0fb1c08-1407-4615-81e6-6083e25edb73    858     FarrierMAT -VETIC MIXING TIPS 180 CC    \N      f       \N      47.8    f       47.8
4290a8d7-0933-4602-8aa2-e151e2226fbc    1167    FarrierMAT -VETTEC ADHERE BLACK 210     \N      f       \N      \N      f       141.75
447d9c04-66dd-4ba2-a777-3c25f350dc43    803     FarrierMAT -VETTEC EQUIPACKS (SILICONE) \N      f       \N      61.85222222     f       61.85
02391eb0-6912-42c9-bafe-f940bd18b711    1142    FarrierMAT -VETTEC EQUIPAK CS 210       \N      f       \N      125     f       125
72be9188-68ae-45c6-8646-432c3224687d    1143    FarrierMAT -VETTEC EQUIPAK SOFT \N      f       \N      125.61  f       125.61
07845d9a-27d9-4c1a-8630-a63103e9ce54    1002    FarrierMAT -VETTEC SUPER FAST   \N      f       \N      141.75  f       141.75
1078ae16-6cc2-438b-a308-073de251c2b9    988     FarrierMAT -VICTORY 7EC \N      f       \N      10      f       10
d1eb75dd-a8d2-40de-8043-b604a390e678    940     FarrierMAT -VICTORY ELITE SHOES SIZE SW \N      f       \N      10      f       10
dacd0bac-48d4-4c0b-9f8d-4989156234ab    976     FarrierMAT -VICTORY ELITE SHOES SIZE XSW        \N      f       \N      10      f       10
0a3d5258-5add-4dc3-bd97-b10f4c2e28fb    867     FarrierMAT -VICTORY RACING PLATE SIZE NO.2 WHITE LABEL 1X4 BOX  \N      f       \N      11.13   f       11.13
68c66acb-f80d-4ad4-a183-e20a9055da23    872     FarrierMAT -VICTORY RACING PLATE SIZE NO.3 PINK LABEL 1X4 BOX   \N      f       \N      11.13   f       11.13
69fa40d5-1692-4791-8d6d-8245f4c89990    868     FarrierMAT -VICTORY RACING PLATE SIZE NO.3 WHITE LABEL 1X4 BOX  \N      f       \N      11.13   f       11.13
6466cf1f-0005-4c3d-b4d5-c1ffc7495ced    873     FarrierMAT -VICTORY RACING PLATE SIZE NO.4 PINK LABEL 1X4 BOX   \N      f       \N      11.13   f       11.13
68ee4330-9888-4e52-90b6-385e15663e65    869     FarrierMAT -VICTORY RACING PLATE SIZE NO.4 WHITE LABEL 1X4 BOXACING PLATE SIZE NO.3 WHITE LABEL 1X4 BOX \N      f       \N      11.13021277     f       11.130212765957447
ba209308-7036-4890-966a-478ae2898168    874     FarrierMAT -VICTORY RACING PLATE SIZE NO.5 PINK LABEL 1X4 BOX   \N      f       \N      11.13   f       11.13
e0dbf0f9-7667-47a3-bbb3-151f899a0698    870     FarrierMAT -VICTORY RACING PLATE SIZE NO.5 WHITE LABEL 1X4 BOX  \N      f       \N      11.13   f       11.13
b462a619-e4b3-43f4-8993-bba08abe2c92    871     FarrierMAT -VICTORY RACING PLATE SIZE NO.6 WHITE LABEL 1X4 BOX  \N      f       \N      11.13   f       11.13
cc8b961a-3554-4162-ab44-2617723a3d4d    1004    FarrierMAT -VICTORY TOE CLIP SIZE 2     \N      f       \N      10      f       10
5b5856f9-3864-47ef-a9b4-49c84d215abf    2483    FarrierMAT -WERKMAN DRAFT SHOE 14F 5 PAIRS/BOX  \N      f       \N      220     f       220
57dc3856-281f-4f0c-a45d-ba9a080bad60    1120    FarrierMAT -WIRE BRUSH - STAINLESS STEEL        \N      f       \N      15      f       15
199187d0-384d-4609-aeac-2e863b9af4aa    2478    FarrierMAT -WIRE BRUSH SMALL    \N      f       \N      15      f       15
16452d83-2dcd-4e60-90b6-61bc84e1b985    1057    FarrierMAT -WORLD RACING PLATE SIZE 5 THOROBREAD        \N      f       \N      11.13   f       11.13
7ca586d3-f6cf-46b5-add0-7beab04c259d    1814    FarrierSRV-Hoof Trimming for 2 Hooves   175     f       \N      \N      f       0
17de3b72-bbc3-412e-a6d8-0e9afcc70def    2099    FarrierSRV-Hoof Trimming for 4 Hooves   300     f       \N      \N      f       0
0fc10512-b15a-44ab-9cab-f35dbdaa1f87    2188    FarrierSRV-New Shoe Fronts and Trim Hinds       525     f       \N      \N      f       0
d043e124-0d18-4f12-9a84-150ba0ce76cd    2189    FarrierSRV-Replace Lost Shoe    175     f       \N      \N      f       0
66b9958d-cf0c-43a2-b517-a74aacf76647    2100    FarrierSRV-Reset 1 Steel Shoes  150     f       \N      \N      f       0
2c697218-914b-4cf1-b92c-2befd2d39b7c    2285    FarrierSRV-Reset Shoes Fronts + Trim Hinds      425     f       \N      \N      f       0
76cd6fba-d519-4df9-9cd3-ce99ed8fd0bb    2388    FarrierSRV-Set 1 Steel Shoes    175     f       \N      \N      f       0
7ca0ef83-f7ff-4bb1-b30b-6c8d706132d9    2190    FarrierSRV-Silicone     \N      f       \N      \N      f       0
e11d33a9-d270-46f6-8482-74c13d595702    1815    FarrierSRV-Studd Hole Tap       \N      f       \N      \N      f       0
ec028052-fcec-4aa2-83c2-c6d150bb16fb    2410    Female cleaners 325     f       \N      \N      f       0
7fb466bd-5ca4-4391-880c-eae5ba2f77fa    2553    Garden - Entry Only Family Package - Adult      47.61904762     f       \N      \N      f       0
469c9f12-7e5c-4817-8647-085991379b47    2560    Garden - Entry Only Family Package - Child      47.61904762     f       \N      \N      f       0
f188cd34-79c3-4688-8780-7b40a82feb2f    2555    Garden - Turfside F&B Lounge Adult 21+ - 2 House Drinks 619.047619      f       \N      \N      f       0
493f8ac2-c815-4610-8576-5ee5b06f37d9    2554    Garden - Turfside F&B Lounge Adult/Child - Soft Package 476.1904762     f       \N      \N      f       0
2506189c-4f9a-48b7-8a90-06daeb61e3c4    2552    General Admission  - Single Entry       9.52380952      f       \N      \N      f       0
f7cb2c4d-5cd9-4cdf-a3db-a884d8f83154    2399    Hobby Horse - Entry     47.6190476      f       \N      \N      f       0
13728b1c-4c5b-4b7b-a9cf-544095c4811f    2354    Hoof Casting (2 Feet)   600     f       \N      \N      f       0
0410f670-a1cd-44d3-903a-567e887ff303    1316    HorseFoodMAT -ACTION MIX - 20 Kg, CAVALOR       \N      f       \N      \N      f       89.25
61472912-6e01-4fbf-89b5-77aa5b7f9c1b    2841    HorseFoodMAT -American Timothy Hay 50KG/BALE Ghantoot   \N      f       \N      225     f       225
d7c3f949-b7cb-4dc3-92a1-f34122b79487    2711    HorseFoodMAT -Baileys No. 26 Senior Soft & Lite 20Kg's  \N      f       \N      110     f       110
74373e26-447b-43ee-9418-247dedede8a5    2860    HorseFoodMAT -COCONUT OIL 5LTR  \N      f       \N      \N      f       115
e27aec45-e0e9-452d-9c97-2f4485ec97c4    1212    HorseFoodMAT -ELECTRODEX ELECTROLYTE - 30LB     \N      f       \N      \N      f       392.0058333333333
bb98141c-0665-4068-8311-36b23c8c912e    1207    HorseFoodMAT -ENDURAMAX-40LB    \N      f       \N      450     f       450
d798da9d-9eae-4c30-a509-2c20b230ceed    1299    HorseFoodMAT -EQUUSROLE OMEGA 3-6-9-OIL \N      f       \N      \N      f       258.066
d591ce83-3c75-424f-8694-3001938604cb    1318    HorseFoodMAT -FIBER FORCE - 20 Kg, CAVALOR      \N      f       \N      125     f       125
157e9755-20f5-4d11-98a3-115073eb073d    2826    HorseFoodMAT -Fescue Hay 450kg/bale     \N      f       \N      900     f       900
2d9afbea-5c20-4002-9342-08ada9618346    2068    HorseFoodMAT -HAVENS GASTRO 20KG        \N      f       \N      \N      f       0
015b8436-7da8-48b1-bce1-99e11b593283    1208    HorseFoodMAT -HIGH FIBRE CUBES = 20KG   \N      f       \N      \N      f       79
1874e875-c33b-4b77-860b-dfc655036f5a    1222    HorseFoodMAT -HIMALAYAN SALT LICKS 3 KGS        \N      f       \N      13.98   f       13.98
ce326da5-871f-4b75-a038-0bb41f92f051    2037    HorseFoodMAT -HORSE CARE 10 MIX -RED MILLS      \N      f       \N      100     f       100
4f659f6c-20b0-4f38-99f0-c2970f35a604    1307    HorseFoodMAT -Havens Slobber Mash 20Kg  \N      f       \N      125     f       125
c7fe47f8-9a2b-4047-b578-0ade8f7a677b    1200    HorseFoodMAT -ICE TIGHT POULTICE-25 LB  \N      f       \N      \N      f       184.125
a932ac54-bb33-4e61-a3ee-a0b8cc6f4b91    2104    HorseFoodMAT -KEVIN BACONS HOOF FORMULA 5KG     \N      f       \N      \N      f       462
66d79c8d-0abd-4102-a885-f525d769747e    2465    HorseFoodMAT -Meadow Hay 15KG/BALE      \N      f       \N      \N      f       48
6fd7d753-003a-4c84-9d45-a69cfb21fb12    1317    HorseFoodMAT -PIANISSIMO - 20 Kg, CAVALOR       \N      f       \N      120     f       120
d2c9d5d8-ec2e-457b-989f-2afc986be1fc    1325    HorseFoodMAT -RED MILLS 10% GULF MIX 20 KG/BAG  \N      f       \N      69.00002        f       69
3810a2ef-97a6-486a-ab18-5d9b751a8d2f    1326    HorseFoodMAT -RED MILLS HORSE CARE 14 20 KG/BAG \N      f       \N      100     f       100
c8e44ed9-e3dc-486f-8b95-1fd0d21f6545    1304    HorseFoodMAT -RHODES HAY        \N      f       \N      \N      f       1.5
a680bbeb-9f9d-421b-aafc-214f9b6f6d89    2834    HorseFoodMAT -RHODES HAY OMAN 10KG      \N      f       \N      \N      f       28.5
41f04af4-8d45-4c80-b6cd-76442117dae3    2836    HorseFoodMAT -Rhodes Grass Small Bales  \N      f       \N      \N      f       33.333333333333336
0747d1e2-a92a-4cc4-a3e4-619efb42e3a8    2828    HorseFoodMAT -Rhodes Hay 450kg/bale     \N      f       \N      1125    f       1125
ede3c280-640d-4f8d-a15a-a560ae324725    1313    HorseFoodMAT -SUPERFORCE 20Kg – CAVALOR \N      f       \N      \N      f       120.75
3827126d-2342-4d71-a660-e57a4999320c    1321    HorseFoodMAT -Speedi Beet 20 kg \N      f       \N      125     f       125
bd2886e0-2360-4de5-86b5-3e310318c1db    1327    HorseFoodMAT -TRADITION MIX 20KG - CAVALOR      \N      f       \N      \N      f       72
581ed3d6-a63e-43e6-9350-4880183773a8    2649    HorseFoodMAT-Meadow Hay 7KG/BALE        \N      f       \N      \N      f       22.5
969f9e64-fa82-4b83-a787-76447117a67d    2605    HorseFoodMAT-Meadow Hay USA     \N      f       \N      1.85714662      f       1.85716
74e27df1-2e92-4e1b-9001-1ae4fd07849f    1934    HorseTransportationSRV-Ajman    \N      f       \N      \N      f       0
581ec835-f5e8-48eb-b3ef-a4d2d4aabe1f    1931    HorseTransportationSRV-Al Ain   \N      f       \N      \N      f       0
0c4f0512-1f65-484c-94b1-8415678a326e    1932    HorseTransportationSRV-Dubai    \N      f       \N      \N      f       0
e58f6cf9-7314-43f4-8e39-7802d62a55a2    1937    HorseTransportationSRV-Fujairah \N      f       \N      \N      f       0
6e674600-2edd-40b7-a5a5-f0892a73acbf    1930    HorseTransportationSRV-Inside Abu Dhabi \N      f       \N      \N      f       0
102f9dc7-345f-437d-873f-5d42ff5c8eb2    1936    HorseTransportationSRV-Ras Al Khaimah   \N      f       \N      \N      f       0
5421c3dd-8380-41fd-aa79-dc30b162d0a1    1933    HorseTransportationSRV-Sharjah  \N      f       \N      \N      f       0
a6bb57e1-1404-459c-a517-05a3047a57f2    1935    HorseTransportationSRV-Umm Al Quain     \N      f       \N      \N      f       0
868b6ea2-8d28-40ac-8bde-e5425ecbe1be    2394    Horsemen’s Lounge 1 Day Pass Adult      1428.5714       f       \N      \N      f       0
364175e9-5190-4284-a7ec-392ebabeb03b    2395    Horsemen’s Lounge 1 Day Pass Child      714.28571       f       \N      \N      f       0
a4a58eb0-7467-4d00-a1af-59fa7374b433    2396    Horsemen’s Lounge 3 Day Pass Adult      3333.33334      f       \N      \N      f       0
4255c947-5255-4960-bcff-df63dceb482e    2397    Horsemen’s Lounge 3 Day Pass Child      1666.6667       f       \N      \N      f       0
881833f8-b607-4ac9-8f68-f7597ae1fd88    2393    Horsemen’s Lounge Table for 10 Person   28571.42857     f       \N      \N      f       0
21394144-76b0-4c09-adb1-973a64760a3b    2392    Horsemen’s Lounge Table for 6 Person    19047.619047    f       \N      \N      f       0
5834a7ec-c23b-4177-bf28-79e0bdeba08e    2805    Hosting Charges \N      f       \N      \N      f       0
95300de2-be4b-46f1-b32b-4e5870880ef7    2705    Kids Area (3-12 y/o) -  (2 Hours Session)       190.47619       f       \N      \N      f       0
d8a306d0-a6b2-454d-8336-21d0649f6a1b    2398    Kid’s Play Area Entry   47.6190476      f       \N      \N      f       0
ed9501f9-4044-4022-bc35-9ce9bfee0d48    529     KitchenMAT -AL AIN WATER 24X330ml       \N      f       \N      9.20080959      f       9.2
39f54ebc-8cca-4b5a-806d-21e1c7263b1c    530     KitchenMAT -ALAIN SPARKLING WATER 1*24 330 ML   \N      f       \N      57      f       57
31833ad0-447d-4430-9a45-0bacd202bde4    2067    KitchenMAT -Al Ain FRESH JUICE – 200ml  \N      f       \N      2.1     f       2.1
6bbbbdb0-403b-458e-b72c-c52cc67c2319    2322    KitchenMAT -BOOM BOOM 24X250ML  \N      f       \N      78      f       78
18d46748-3434-4968-aed8-c7bc1abd3fc7    509     KitchenMAT -BOTTLE BRUSH SMALL  \N      f       \N      11      f       11
22fe18e9-b926-45ad-b163-6073117992cb    2804    KitchenMAT -BROWN Sugar Sticks1000/ BOX \N      f       \N      77      f       77
dfc9c797-7a10-4654-ab5f-4f1b17a5a45a    532     KitchenMAT -COCONUT WATER 1*24*330ML    \N      f       \N      126     f       134
840cc7aa-b646-40d1-a96c-8556357b9a51    496     KitchenMAT -COFFEE MATE 400GRMS.        \N      f       \N      8.53    f       8.53
cdf7e325-fb4a-4d57-bb66-637452b281f1    513     KitchenMAT -COFFEE WARMER       \N      f       \N      30.87666667     f       30.87666666666667
73e39ab9-ce2b-42f8-8ed7-d9c6ae39ffe5    512     KitchenMAT -COFFEE WARMER BIG   \N      f       \N      57.5    f       57.5
a4dcbb6d-6fd2-469a-a9ab-16ea53e04722    497     KitchenMAT -CRYSTAL GLASS 1X12  \N      f       \N      156     f       156
749c7a67-ed92-4986-b8d2-a57be3eb2f86    524     KitchenMAT -Coca-Cola 1*24      \N      f       \N      49      f       49
df006032-aeac-4ed0-85d9-086a3d9fd399    504     KitchenMAT -DISPOSABLE PLASTIC SPOON    \N      f       \N      2.23714286      f       3.15
c203f4f9-6808-4d73-aa54-d638dbbecdc3    531     KitchenMAT -DUBAI ENERGY DRINK 24X250ML \N      f       \N      \N      f       65
3d73c786-ab41-46b6-b5bc-7ccfaedbcdc5    516     KitchenMAT -FENILI CAPPUCINO SET 1X12   \N      f       \N      9.92    f       9.92
e62d1554-80e3-4ce5-9001-28f5d7d5a79d    487     KitchenMAT -FOAM PLATE  \N      f       \N      105     f       105
c6e390a0-8961-406c-bbfc-d4a27595da0c    2052    KitchenMAT -Falcon Vinyl Gloves powder free 100’s       \N      f       \N      6.405   f       9.5
7b2e96c8-f8d7-4579-ab2c-2226b94454ec    523     KitchenMAT -Gatorade drinks 1*24        \N      f       \N      113.19  f       113.75
235b06b0-a116-4cab-8da6-854bb5cc3c3c    515     KitchenMAT -JUICE TUMBLER VINTIA        \N      f       \N      55.1    f       55.1
a90cd6a1-71e6-4423-8461-8ead85197500    507     KitchenMAT -LACNOR JUICE 32x200ml       \N      f       \N      36.0025 f       36
6accfb9c-a8b0-4b26-bbfe-7f9102e592a7    505     KitchenMAT -LIPTON GREEN TEA 1x12       \N      f       \N      19.85125        f       20
dda13534-45b7-4fc4-91b6-99f2e1769242    501     KitchenMAT -LIPTON TEA BAGS 36 X 100    \N      f       \N      10.5    f       9.75
da1dc2b0-9965-46c0-bef6-43f369373cac    528     KitchenMAT -NESCAFE CLASSIC – 750gm     \N      f       \N      \N      f       41.4625
f610897b-2d6e-4629-8609-ed67e4e7ba96    38      FixedAsset-Acc.Amort WIP - Intangible Assets    \N      f       \N      0       t       \N
44dc930c-6804-4ddf-90d3-5ae0816b8d4a    489     KitchenMAT -NESCOFEE-200G RED MUG       \N      f       \N      26.53964286     f       26
5b12eb6a-0721-4dd2-9caa-c4e3b055c868    490     KitchenMAT -PAPER CUP 1X1000    \N      f       \N      \N      f       62
681cdd66-7394-4981-8f17-10a92b9e8672    517     KitchenMAT -PAPER CUP 1X1000 QUALITY FIRST      \N      f       \N      84.285  f       79
ef33d1ec-8498-40be-8d67-8ebebc438c04    491     KitchenMAT -PERRIER WATER 1 X 24        \N      f       \N      63.05222222     f       63
550fa01c-13e2-46c1-b3e5-98ce42373e3f    2121    KitchenMAT -Plastic Food Wrap Roll 30cm 1kg     \N      f       \N      13.65   f       13.65
57bc9df9-26d9-4379-bd1c-d18e50fc1e45    2020    KitchenMAT -Plastic Fork 50’s Flacon – Black Colour     \N      f       \N      4.04766667      f       4.6
e6f32059-9f6d-46e3-bbe3-d986fdf52483    526     KitchenMAT -Plastic Glass 7 OZ CLEAR 1*1000     \N      f       \N      87      f       154
04c5a79f-72cf-4982-b5a6-be8c051c8b81    492     KitchenMAT -RAINBOW MILK 1 X 96X6OZ     \N      f       \N      209     f       209
4bc9f5c4-0403-4c33-85e7-19bb0f51d8c6    520     KitchenMAT -RAINBOW MILK 1X48X385ML     \N      f       \N      221.07  f       221.065
9a28a5e0-2569-44cc-bcea-31d5b34bb065    493     KitchenMAT -ROSE WATER  \N      f       \N      6.81363636      f       6.9
d0b4593b-4193-45e1-8d34-74ac71441037    2041    KitchenMAT -Ripple Kraft Brown Paper Cup 4Oz    \N      f       \N      123.273 f       146
94e09f04-61ec-4e80-89f1-5bac8774f2aa    2054    KitchenMAT -Ripple Kraft Brown Paper Cup 8Oz    \N      f       \N      \N      f       195
a6667c0c-b4f5-4448-b538-9e7e45aa1823    502     KitchenMAT -SAFFRON TAJ MAHAL 4 GRM.    \N      f       \N      55.666  f       55.667142857142856
ffaf1406-8682-4534-a9e6-d85dc35363e8    499     KitchenMAT -SUGAR 2 KG  \N      f       \N      5.23375 f       4.9
189ca26d-4d97-4cf2-9058-aa962c8ce3ad    525     KitchenMAT -Seven up 1*24       \N      f       \N      49      f       49
042a6737-ee35-4406-a4c2-2fc9d3acc5ab    514     KitchenMAT -TEA ESTIKAN-1X12 SOLITAIRE CRYSTAL  \N      f       \N      23.08   f       23.08
dd3ad41a-63e8-460d-a36d-116755b253dd    2055    KitchenMAT -Wooden Chip Fork 100’s - Falcon     \N      f       \N      4.86545455      f       5
cf0e9150-6d49-4398-b4b2-92e7eab44d0c    503     KitchenMAT -ZATHAR      \N      f       \N      5.00384615      f       5.003846153846154
e9b72404-98e3-4445-a5f1-61157841077a    2584    KitchenToolsMAT -AL AIN WATER GLASS 1*24*330 ML \N      f       \N      57      f       55
025681c4-a5cc-4a71-a165-bc7473b93cce    783     KitchenToolsMAT -COLEMAN CHAIR GREEN    \N      f       \N      95.5    f       95.5
6ef99ab2-08cc-48ea-982c-23f2101d2f74    780     KitchenToolsMAT -COMFORTER DOUBLE       \N      f       \N      \N      f       180.95
c35dafa5-60fb-4065-94d0-47665704793f    619     KitchenToolsMAT -COMFORTER SINGLE       \N      f       \N      65      f       55
711f1192-8b3c-4f7b-b56a-108bb2b3e810    775     KitchenToolsMAT -LEHMANN SINGLE DOOR UNIT       \N      f       \N      105.5   f       105.5
49069504-23e7-44ce-b1eb-6e8fe5a35874    776     KitchenToolsMAT -MATRESS        \N      f       \N      131.53846154    f       70
c5224f80-72aa-4dc9-8899-0b7a24bcbdf9    2307    KitchenToolsMAT -PRINCESS ARM CHAIR FCPP WHITE  \N      f       \N      \N      f       37
0d85471f-bb7e-4265-b632-8efb7e7efc88    2308    KitchenToolsMAT -SQUARE TABLE DIA FCPP 85×70CM COSMO WHITE      \N      f       \N      \N      f       165
6620acd9-70d4-4e77-be59-e17833ccace2    2515    LiverySRV – Standard Package (Advance Paid)     4500    f       \N      \N      f       0
a8626ad0-b52a-46e7-b11c-ae477542586e    2715    LiverySRV – Temporary Stabling Fees     85      f       \N      \N      f       0
28c29d9f-c9d7-4675-ab3e-4c51501d0aae    2365    LiverySRV- Livery notice period penalty \N      f       \N      \N      f       0
5ed60754-2476-4d40-8dd1-1188ca9ed413    2315    LiverySRV-Arena Fee. Livery     100     f       \N      \N      f       0
348eaf54-24b3-4e6b-8692-d5d4ffc4c7c8    2110    LiverySRV-Groom Charges \N      f       \N      \N      f       0
6c0f5c8f-7ecf-48d5-bf94-50a0cb73d9a7    1841    LiverySRV-HORSE HAIR CUT. Livery        \N      f       \N      \N      f       0
af908005-6fca-4cbe-8f7f-9a17f6140f50    1840    LiverySRV-HORSE TRAINING. Livery        \N      f       \N      \N      f       0
07ecf4d5-6634-4f9c-a941-22ddf799293f    1842    LiverySRV-HORSE TRANSPORTATION.Livery   \N      f       \N      \N      f       0
a1af9cd9-d465-4cdd-b087-8154a565e6e8    2341    LiverySRV-Horse Clipping-Blanket Clip   250     f       \N      \N      f       0
4b79f1c2-b4b0-427d-aabc-5cfac17ef87c    2343    LiverySRV-Horse Clipping-Chaser Clip    200     f       \N      \N      f       0
bdb95c17-955e-414a-a4c1-3f0123fecc7b    2339    LiverySRV-Horse Clipping-Full Body      400     f       \N      \N      f       0
460e2781-6b91-44da-92b7-16aaf8708490    2340    LiverySRV-Horse Clipping-Hunter Clip    320     f       \N      \N      f       0
f017c6dd-536a-4450-93aa-1393dcf8695e    2342    LiverySRV-Horse Clipping-Trace Clip     250     f       \N      \N      f       0
e9c00825-0f40-44dd-8104-45997223953d    1843    LiverySRV-Quarantine. Livery    \N      f       \N      \N      f       0
ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2069    LiverySRV-Standard Package. Livery      4500    t       \N      \N      f       0
102bcd15-26cb-487c-b1ec-5367fe0b6a3e    1844    LiverySRV-Swimming Pool. Livery \N      f       \N      \N      f       0
000c456c-3133-4de6-a0f8-9c50638fec67    2409    Male cleaners   300     f       \N      \N      f       0
68c9d9fe-bdc7-4f4a-adbd-8e3c1de10cdf    2695    Mall Revenue - Annual License Fee for External Area     150     f       \N      \N      f       0
c9fbdbee-8bf2-4c2d-8638-d8239558f2b0    2694    Mall Revenue - Chillers Charges 150     f       \N      \N      f       0
fd8d8682-e512-492b-8f56-46816146394c    2693    Mall Revenue - Variable/Turnover Rent   150     f       \N      \N      f       0
66d6605d-d824-49cc-8ce0-6445502903e4    2539    Mall Revenue Marketing Contribution     150     f       \N      \N      f       0
2cfd54da-a87d-46de-bb38-59ef6bb6dbda    2540    Mall Revenue Service Charge     150     f       \N      \N      f       0
433c93cc-75c9-4893-9d7c-82e29ccc2623    2538    Mall Revenue Unit Rent  150     f       \N      \N      f       0
4c5ee6c7-6c40-4c6f-97ba-984f1d746094    1940    MembershipSRV-Membership-Classes Fees   \N      f       \N      \N      f       0
556d316c-940f-454a-874e-fd39aa43fc60    1938    MembershipSRV-Membership-Membership Renewal     \N      f       \N      \N      f       0
0d1a4b4d-8db1-441d-92d5-516ef5bbf261    1939    MembershipSRV-Membership-Registration Fees      \N      f       \N      \N      f       0
530c03c2-1d1b-462e-b60d-4748d3ceb73a    2677    Merch Store Sales Items 47.61904762     f       \N      \N      f       0
03e54621-c7de-4917-8841-83dda7f1115b    2324    Other Miscellaneous Revenues    \N      f       \N      \N      f       0
75f8670c-007d-414b-b2ba-4b45a416b7c9    2335    OtherSRV -FED -FEI Passport Revalidation (Renew)        \N      f       \N      \N      f       0
ec376787-86ed-478a-8ecf-cbfd809b8cb6    2338    OtherSRV- FED - Change of Horse Name on National Passport       \N      f       \N      \N      f       0
6ba0356a-7063-41e8-9e48-8c1bebc89a85    2336    OtherSRV- FED -Duplicate National Passport      \N      f       \N      \N      f       0
c1a1b81f-c39f-4eb4-a9b9-29995153693c    2337    OtherSRV-FED -Change of Horse Name on FEI Passport      \N      f       \N      \N      f       0
e662bb5a-68e1-4827-8b72-e75c620cbd14    2333    OtherSRV-FED -Change of Horse Ownership \N      f       \N      \N      f       0
5895e54e-2985-422a-b416-5fdaf52a7dca    2334    OtherSRV-FED -Duplicate FEI passport    \N      f       \N      \N      f       0
175cce03-0645-4468-9bb2-b63b53153e09    2330    OtherSRV-FED -Horse FEI Registration / Renewal for Season       \N      f       \N      \N      f       0
740cd527-345f-43a1-a397-dcba51bd0dcf    2327    OtherSRV-FED -Horse Registration / Renewal for Season   \N      f       \N      \N      f       0
d061e51a-c3b6-4e5a-b8f1-9b47c28a1afe    2332    OtherSRV-FED -New FEI Passport  \N      f       \N      \N      f       0
2223610a-39d6-4a1c-824c-501b21b7dbea    2331    OtherSRV-FED -New National Passport     \N      f       \N      \N      f       0
6764c1fb-1c14-41a7-8fb8-bbf4eb50a01c    2328    OtherSRV-FED -Rider Registration / Renewal for Season   \N      f       \N      \N      f       0
5e54d971-c059-46cd-a3e1-92f15da8b14a    2107    OtherSRV-Fediration Horses      \N      f       \N      \N      f       0
b8d4a2f1-356c-43c2-808a-0ee49da646f2    2108    OtherSRV-Fediration Riders      \N      f       \N      \N      f       0
08facc5a-2ae3-4438-b60c-ece18a1e4f86    2413    OtherSRV-Resale Hire - Arc Chair - Beige 50X56XH88 CM   \N      f       \N      \N      f       0
c0a4927d-25e8-478a-b9e3-88e10d94abf8    2504    OtherSRV-Resale cleaning services       \N      f       \N      \N      f       0
cd65951e-f20e-498e-99a7-0545f7ea387b    2329    OtherSRV-Rider FED -FEI Registration / Renewal for Season       \N      f       \N      \N      f       0
096910d7-fdd7-4467-a28a-8f4adf094949    2323    OtherSRV-Showjumping Event Entry Public \N      f       \N      \N      f       0
a3762bf8-bd0e-4ab9-a479-e71d92610372    2403    OtherSellSRV Photo Airdrop      4.76190476      f       \N      \N      f       0
4bb82c1f-bb77-4f43-b253-91983e2ba469    356     ClinicMAT -Blood Collection Tube (Purple - 5ml) 35.3    f       1       \N      f       35.3
63d3723b-883a-40b9-96a2-4bc067e477d4    36      FixedAsset-Acc.Dep WIP - Tangible Assets        \N      f       \N      0       t       \N
0d1f64f3-1a9e-40d6-8772-5478bbc29eb5    28      FixedAsset-Agriculture machinery and equipment  \N      f       \N      0       t       \N
adf6b4c5-e066-4bee-8865-fc6a435d32c8    22      FixedAsset-Distribution and Conditioning Equipment      \N      f       \N      0       t       \N
ebbf8bdd-9a67-47a2-ad3e-76bfbc95257b    23      FixedAsset-Electrical and Power Generation      \N      f       \N      0       t       \N
b44c5054-6b6e-4be5-bd94-05a5e69d5d6b    30      FixedAsset-Equestrian Equipment \N      f       \N      0       t       \N
8cde1960-e463-4af5-ae9d-7374fdfd1086    19      FixedAsset-Furniture and Fixtures       \N      f       \N      0       t       \N
31dcf378-fe9c-41a5-b01f-e33afa3fa964    29      FixedAsset-Heritage Assets      \N      f       \N      0       t       \N
d129a6c7-f2ef-4e8e-8e9e-c46241a1b885    26      FixedAsset-Horses       \N      f       \N      0       t       \N
350a656d-c6db-44dc-b480-b44acc11c004    21      FixedAsset-Information Technology Assets        \N      f       \N      0       t       \N
52bb3bad-ec4b-4fef-9703-fcf92662c039    18      FixedAsset-Infrastructure       \N      f       \N      0       t       \N
2cdee950-fd85-4977-91f9-e851f717092b    33      FixedAsset-Lands        \N      f       \N      0       t       \N
9652a0fb-2e41-4f67-9869-7f6c5338e3a7    34      FixedAsset-Low Value Assets     \N      f       \N      0       t       \N
cc67e181-6224-4d51-bef7-8f26b12c1d12    27      FixedAsset-Mechanical machinery and equipment   \N      f       \N      0       t       \N
7fbd1d1b-6571-4e41-985a-c87cb2c2899c    24      FixedAsset-Medical Equipment    \N      f       \N      0       t       \N
0eba6c1e-5fee-45c5-9e86-32ed867f9de9    32      FixedAsset-Other Intangibles    \N      f       \N      0       t       \N
d92f4e03-8c77-4603-90f2-9be32a88a316    25      FixedAsset-Plants       \N      f       \N      0       t       \N
125ec3b9-6198-470c-ac6a-55055a292fb6    2404    OtherSellSRV- Photo Airdrop & Print     33.33333333     f       \N      \N      f       0
08bc488d-3482-4342-945a-b5e29740424e    1853    OtherSellSRV-Photo Print        30      f       \N      \N      f       0
5649c3fe-e90d-49de-9ce4-ef278396e57f    2772    OtherSellSRV-Pny Square - Carousel Ride 23.80952381     f       \N      \N      f       0
70ca35fe-f1e6-4706-bc22-0630d1f684be    2770    OtherSellSRV-Pny Square - Pony Ride     47.61904762     f       \N      \N      f       0
393a71d5-7d9f-431d-99fa-d04238eea61d    2771    OtherSellSRV-Pny Square - Pony Ride With Photo  85.71428571     f       \N      \N      f       0
000306a3-cb4a-4023-9b75-f09c74077c4d    2665    OtherSellSRV-Pop-Up 2026 Photobooth Digital     9.52380952      f       \N      \N      f       0
51fead06-1475-4004-9f75-b032f4f921a3    2664    OtherSellSRV-Pop-Up 2026 Photobooth Print       28.57142857     f       \N      \N      f       0
d3fbb1f8-7ba7-4016-8827-f1d4c4d82dc6    2284    OtherSellSRV-Provision of Racing Data & Television Footage      \N      f       \N      \N      f       0
caa0293d-df4c-45e1-9ffe-93322cee707a    1852    OtherSellSRV-Quarantine Non-Livery      \N      f       \N      \N      f       0
92f17559-30c8-44e3-a359-85b33209f7ed    1851    OtherSellSRV-Rent Horses        \N      f       \N      \N      f       0
27e7c54b-10dd-46d5-a879-b323f354252d    2243    OtherSellSRV-Scraping Income    \N      f       \N      \N      f       0
9d01fab0-e813-4045-806f-9200e9e1d95b    1854    OtherSellSRV-Sponsership Revenue        \N      f       \N      \N      f       0
b14a5992-be60-4cf0-9795-ba0053ccbf40    2777    OtherSellSRV-Ticketing - Majlis by the Turf - Ifthar -  Adult   347.6190476     f       \N      \N      f       0
e4f38754-221a-4200-880c-7216df50e70d    2778    OtherSellSRV-Ticketing - Majlis by the Turf - Ifthar -  Child   173.8095238     f       \N      \N      f       0
ab5bdea4-34b4-4898-a421-74149eb58983    2779    OtherSellSRV-Ticketing - Majlis by the Turf - Suhoor    285.7142857     f       \N      \N      f       0
02d29035-9446-4521-b2b1-f6bc4fdf6a8d    2105    RaceDaySRV-Garden Entry Ticket Adult    76.19047619     f       \N      \N      f       0
56740423-4189-4c53-ab97-72e65f074011    2106    RaceDaySRV-Garden Entry Ticket Child    57.14285714     f       \N      \N      f       0
f960526c-f41a-4b36-8400-1cec15a9b982    2261    RaceDaySRV-General Admission Season Pass        66.66666667     f       \N      \N      f       0
c3819872-eade-4e15-818e-bf1671e6d703    1849    RaceDaySRV-In-kind prizes, audience race        \N      f       \N      \N      f       0
59eff737-d891-4383-9c31-e709adb78ea8    1845    RaceDaySRV-Jumping prizes       \N      f       \N      \N      f       0
ed2a4782-ec42-4b22-a123-379ff949cbcb    1847    RaceDaySRV-Race prizes  \N      f       \N      \N      f       0
78ef904f-5d0e-463d-8a5d-9bfd419735e9    2780    RaceDaySRV-The  GoldCup  Garden Adult   142.85714       f       \N      \N      f       0
98517a43-7cd8-4f26-9331-9ba9eb7f07bc    2773    RaceDaySRV-The Gold Cup Garden Child    57.142857       f       \N      \N      f       0
20fca693-651b-4d85-99ca-79373f793134    2774    RaceDaySRV-The Gold Cup General Admission       19.047619       f       \N      \N      f       0
6eb1f29f-e43f-45d2-8cb8-7e831aed77d7    2775    RaceDaySRV-The Gold Cup Premium Dining Experience       9523.80952      f       \N      \N      f       0
5fbf8ec5-c4a5-4548-b982-5dd5d0e42007    2255    RaceDaySRV-The President Cup  Garden Adult      142.85714       f       \N      \N      f       0
68a9610f-fb5d-4cee-8875-ba26bdb714d1    2256    RaceDaySRV-The President Cup Garden Child       57.142857       f       \N      \N      f       0
4cd7f10b-8d4c-44a7-81c3-7ce69dcb9ea7    2253    RaceDaySRV-The President Cup General Admission  19.047619       f       \N      \N      f       0
503c40b9-5edc-41b8-a9f7-2835575b4c31    2259    RaceDaySRV-The President Cup Parade Ring Full Package   1190.47619      f       \N      \N      f       0
f0e9ef38-84a1-4bdf-a563-ec8f8376f470    2260    RaceDaySRV-The President Cup Parade Ring Non-Alcoholic Package  952.38095       f       \N      \N      f       0
326ca57d-b318-4908-8db5-984bb9d92a02    2637    RaceDaySRV-The President Cup Premium Dining Experience  9523.80952      f       \N      \N      f       0
1a40e618-8262-4692-8089-2eb07c6c40b8    2257    RaceDaySRV-The President Cup Trackside Experience Full Package  1190.47619      f       \N      \N      f       0
c7ed9e9c-fdb6-4331-a90d-f099450af320    2258    RaceDaySRV-The President Cup Trackside Experience Non-Alcoholic Package 952.38095       f       \N      \N      f       0
789177fd-3b57-48cf-85ec-59fcfa25b632    2869    RaceDaySRV_  F&B Revenue Share  \N      f       \N      \N      f       0
292a8fd5-940c-41bc-ab86-358fa13154d0    2345    Radiography (per area)  500     f       \N      \N      f       0
a5ac7244-08ae-4d6e-9c2d-2033b3390e8b    2353    Remedial Shoeing (1 Shoe Only)  250     f       \N      \N      f       0
1588c836-2b9e-4ee1-ad25-386e38d64dd6    2352    Remedial Shoeing (Fronts Only – 2 Shoes)        500     f       \N      \N      f       0
3e664d7d-05a2-441c-955e-d989b698caff    2351    Remedial Shoeing (Full Set – 4 Shoes)   1000    f       \N      \N      f       0
a7b2b15a-c27c-4598-885c-d725add3f571    2511    Remedial extra(bars)    300     f       \N      \N      f       0
d4291832-d504-45c9-a5b3-55da7091ea6a    2512    Remedial extra(rails)   300     f       \N      \N      f       0
c05a5b61-1d9a-4160-a043-bdb50494251e    2348    Replace Cast Shoe From Same Farrier     0       f       \N      \N      f       0
4bf6fe15-7060-4367-bc32-ab02a05978c0    358     ClinicMAT -Blood Collection Tube (Red - 5ml)    54.45   f       1       54.446  f       54.45
d789e4ea-ebbd-4ca3-bf78-00de4a26ea19    326     ClinicMAT -Blood Collection Tube (Red- 9ml)     141.75  f       1       141.75  f       141.75
afecfe2e-e939-479d-8b11-0d9046a02de8    403     ClinicMAT -Blood Collection Tube 0.5ml (Green)  102.63  f       1       102.63  f       102.63
86947ea2-a84b-468b-96c2-c03766c044bd    404     ClinicMAT -Blood Collection Tube 0.5ml (Purple) 102.63  f       1       102.63  f       102.63
2f0bda8e-353a-4473-b119-b2801c5900eb    302     ClinicMAT -Butorgesic 20ml (10mg/ml)    450     f       1       \N      f       145
d1f8655f-55fc-4f1d-aaf6-4367448fc5da    413     ClinicMAT -Ca B Gluconate 24% 500ml     \N      f       1       \N      f       29.4
ed293708-601e-46b4-9c35-ff6fada3776b    2776    ClinicMAT -Calvenza EIV/EHV vaccination 280     f       1       95      f       95
59588194-1e99-49a4-9e83-7b5421412cd7    299     ClinicMAT -Cartrophen Equine Forte (4ml bottle) 149.23  f       1       \N      f       149.231
4e5eb9d8-582a-4338-b5fa-8b7a452a038f    229     ClinicMAT -Charcoal Swabs       20      f       1       \N      f       20
302a3800-c8a1-44d1-a7f9-25196127dac2    380     ClinicMAT -Combination Cap (100pce/box) 367.38  f       1       367.38  f       367.38
60dc5c9c-8c73-4f05-8df1-96224fb449ed    286     ClinicMAT -Cooling Gel 500g     37.8    f       1       37.8    f       37.8
04739009-1adf-4a2f-b74b-6bfb2dc715cb    392     ClinicMAT -Copper Sulphate 500g 180     f       1       120     f       120
02adabfb-7ae7-4ee3-a2ff-449446f00630    221     ClinicMAT -Cotton Wool (500g)   12.13   f       1       12.12611111     f       12.13
6e361a06-40de-4df1-9d96-97fc085748fd    31      FixedAsset-Software     \N      f       \N      0       t       \N
210a0d1b-9488-461f-80e3-a0702da70014    20      FixedAsset-Vehcles &Transportation equipment    \N      f       \N      0       t       \N
46560c19-d0fa-426c-9bce-f8dca0602146    37      FixedAsset-WIP - Intangible Assets      \N      f       \N      0       t       \N
bb29f102-0372-4244-80ed-580b502cc9e8    35      FixedAsset-WIP - Tangible Assets        \N      f       \N      0       t       \N
0229cd01-f6d9-4348-af1a-b285fedbaa41    17      FixedAsset-buildings    \N      f       \N      0       t       \N
593fab93-8ff2-4866-9b65-8961ca688a71    2286    Horse Medical Treatment \N      f       \N      0       t       \N
a9bd00b3-0184-485e-857c-012b10670cef    2346    Replace Lost Shoe (Missing Shoe)        175     f       \N      \N      f       0
7b9cd680-9abf-4498-b0d4-7b90f3a49aca    2347    Replace Lost Shoe From Another Farrier  175     f       \N      \N      f       0
431a11b1-adbb-4c4e-96e5-e07e4fdd4ad7    2355    Resin Glue Application (2 Hooves)       250     f       \N      \N      f       0
5fec8993-69bf-4925-887c-8a05351fa575    2294    Revenue - Entry Fees Players    \N      f       \N      \N      f       0
3ecf69c5-7f41-40cc-a1e7-5269ed514b6c    2390    Revenue -ADEC Dressage Competition  Entry Fees Players  \N      f       \N      \N      f       0
173479ba-f5dd-4c8f-bf73-e9082a9cb271    2563    RidingSchoolSRV- Afternoon Private Lessons - 10 Lesson Package (SH)     7200    f       \N      \N      f       0
90bc8bfe-7b17-4895-abde-020d615563c0    2562    RidingSchoolSRV- Afternoon Private Lessons - 10 Lesson Package - On Own / Leased Horse  4500    f       \N      \N      f       0
542d9ea8-41a1-40fc-8079-d6d979790594    2536    RidingSchoolSRV- Afternoon Private Lessons - On Own / Leased Horse      500     f       \N      \N      f       0
8b8881fc-611e-4b21-ba00-c9593e17278e    2535    RidingSchoolSRV- Afternoon Private Lessons - On School Horse (SH)       800     f       \N      \N      f       0
9b0b0a5c-aff3-4cdd-b2b0-d8ca2433a0f9    2207    RidingSchoolSRV- Birthday Party One -off        300     f       \N      \N      f       0
3427bdeb-589a-458b-a8be-d2a6ab832f8d    2172    RidingSchoolSRV- Birthday Party VIP Package     4000    f       \N      \N      f       0
17034928-6f54-447f-9023-08ea9c3978e1    1826    RidingSchoolSRV- Morning Private Lessons - 10 Lesson Package (SH)       4500    f       \N      \N      f       0
a6087b1d-ee84-47c6-b16a-0e1f27cf9383    2534    RidingSchoolSRV- Morning Private Lessons - 10 Lesson Package - On Own / Leased Horse    3600    f       \N      \N      f       0
e00bd8cd-9730-4f15-bea8-ba1a18a8d4c2    1822    RidingSchoolSRV- Morning Private Lessons - On Own / Leased Horse - instractor   400     f       \N      \N      f       0
1e476706-bb4e-4021-9f4d-c65b82f41f50    1824    RidingSchoolSRV- Morning Private Lessons - On School Horse (SH)  - instractor   500     f       \N      \N      f       0
a5172aa4-43b3-4032-9d6f-2f5ade0e8b67    2558    RidingSchoolSRV- Therapeutic Private Lesson - On School Horse (SH)      500     f       \N      \N      f       0
d9f79728-0b6c-4ceb-b8fa-0611cb06bc24    2557    RidingSchoolSRV- Therapeutic Private Lessons - 10 Lesson Package (SH)   4500    f       \N      \N      f       0
36a173bd-25ee-42d6-a2a0-afad51ce9e4b    2506    RidingSchoolSRV-1-Day Pony Camp 400     f       \N      \N      f       0
d9e11553-7e29-4e64-b202-aced19094468    2248    RidingSchoolSRV-3-Day Pony Camp 1100    f       \N      \N      f       0
626057b7-197b-4a7c-a76c-923bf54011b4    1816    RidingSchoolSRV-Beginners Course - Intro        1800    f       \N      \N      f       0
e99d57b7-369e-49a0-8341-4b77bb3d291e    1817    RidingSchoolSRV-Beginners Course - Plus 1800    f       \N      \N      f       0
e951f069-328d-4f41-abb1-5394bb3dee01    2050    RidingSchoolSRV-Camping \N      f       \N      \N      f       0
7e1fb3bb-7624-48a6-ad80-a7ad1f8fccd9    1820    RidingSchoolSRV-Group Lessons - 10 Lesson Package (SH)  2000    f       \N      \N      f       0
0227ba40-40d6-46f4-afa1-2dddf2d58f62    1818    RidingSchoolSRV-Group Lessons - On Own / Leased Horse   150     f       \N      \N      f       0
11caa0a9-7970-481c-a397-2b1ca6c05054    1819    RidingSchoolSRV-Group Lessons - On School Horse (SH)    225     f       \N      \N      f       0
0687a908-48df-47d2-8719-e78a8bd90df4    2267    RidingSchoolSRV-Horse leasing   \N      f       \N      \N      f       0
45737d54-327e-4779-92ee-4358d1562d44    2268    RidingSchoolSRV-Horse-Pony Hire for Parties     600     f       \N      \N      f       0
95043bab-42c3-4a07-a08f-aaa375ddc298    2810    RidingSchoolSRV-Instructor Schooling - 10 Session Package (30 mins)     2700    f       \N      \N      f       0
2cdd850d-c5c0-43d8-a6e0-e01c64e8eb14    2811    RidingSchoolSRV-Instructor Schooling - 10 Session Package (45 mins)     3600    f       \N      \N      f       0
f6b47cdd-c7bf-4b85-91ae-ab9a281557d8    2813    RidingSchoolSRV-Instructor Schooling - One Session (30 mins)    300     f       \N      \N      f       0
eb992fd0-9e88-426d-879a-18914381830a    2812    RidingSchoolSRV-Instructor Schooling - One Session (45 mins)    400     f       \N      \N      f       0
c5e81176-d6b0-45da-860c-27a44915b82d    2049    RidingSchoolSRV-Lunge Schooling - 10 Sessions Package   1800    f       \N      \N      f       0
7c6250df-0e75-44f4-bb0f-084108934de5    2048    RidingSchoolSRV-Lunge Schooling - One Session   200     f       \N      \N      f       0
3b16b794-3c56-43aa-8664-4ca858a41fa7    1839    RidingSchoolSRV-Pony Pals       150     f       \N      \N      f       0
4acd679d-f2af-4336-9813-13fc93407b2a    1838    RidingSchoolSRV-Pony Ride       50      f       \N      \N      f       0
8f7aae09-d12b-42d6-9b43-da5bb9e0f5ba    1827    RidingSchoolSRV-Private Lessons - 10 Lesson Package (SH) - Head Instructor      4500    f       \N      \N      f       0
db82b8d1-d054-482b-b148-a5472bf792c9    1823    RidingSchoolSRV-Private Lessons - On Own / Leased Horse - Head Instructor       360     f       \N      \N      f       0
fb812922-bc6b-43c4-9785-3142d94dd3e2    1825    RidingSchoolSRV-Private Lessons - On School Horse (SH)  - Head Instructor       500     f       \N      \N      f       0
6dd4c68f-a96c-42be-a82d-dc4e96849c68    2505    RidingSchoolSRV-Self-Ride       200     f       \N      \N      f       0
93107bad-ced8-4775-90b8-2252c35cf894    1835    RidingSchoolSRV-Semi-Private Lessons - 10 Lesson Package (SH) - Head Instructor 3000    f       \N      \N      f       0
290bb220-0bde-4b10-96d1-a18614482e2e    1834    RidingSchoolSRV-Semi-Private Lessons - 10 Lesson Package (SH) - instractor      3150    f       \N      \N      f       0
919229d4-7f52-443c-9276-db44f218ec30    2537    RidingSchoolSRV-Semi-Private Lessons - 10 Lesson Package - On Own / Leased Horse        2520    f       \N      \N      f       0
c98caa16-a1d6-4597-a40f-357798ee3a41    1831    RidingSchoolSRV-Semi-Private Lessons - On Own / Leased Horse - Head Instructor  280     f       \N      \N      f       0
73fff75c-033d-41fd-9999-32315c9fc655    1830    RidingSchoolSRV-Semi-Private Lessons - On Own / Leased Horse - instractor       280     f       \N      \N      f       0
0aff01aa-64e2-41ad-8e56-3345a138d151    1833    RidingSchoolSRV-Semi-Private Lessons - On School Horse (SH)  - Head Instructor  350     f       \N      \N      f       0
f37572f0-6e47-4c3e-b616-5d5774d12623    1832    RidingSchoolSRV-Semi-Private Lessons - On School Horse (SH)  - instractor       350     f       \N      \N      f       0
59aaed5e-5bf1-49e0-8664-ce53462bfc82    2356    Rubber / Plastic Shoes (2 Feet) 600     f       \N      \N      f       0
25dd768c-1c33-4327-8572-c71d9f2a01a8    1846    SRV-Jumping Sponsorship \N      f       \N      \N      f       0
5423f05a-e678-4ca9-a40d-be979b951d02    2510    SRV-Popup Sponsorship   \N      f       \N      \N      f       0
9a876bf0-62a1-4bb0-9436-6f994880d195    1848    SRV-Racing Sponsorship  \N      f       \N      \N      f       0
f2503058-9bd2-4ad2-b8ad-34fc6715df46    2782    SRV-Social Contribution Ma'an Sponsorship       \N      f       \N      \N      f       0
f09ab816-8cea-4f27-94f3-947eac1dad64    2701    Saddle Club 1 Day Pass - Adult 13+      761.90476       f       \N      \N      f       0
9bde6425-074b-4921-97dc-ef324508ec2b    2702    Saddle Club 1 Day Pass - Child (3–12)   380.95238       f       \N      \N      f       0
f449bc80-4083-4430-941f-037c5c86a937    2703    Saddle Club 3 Days Pass - Adult 13+     1904.7619047    f       \N      \N      f       0
7290a2b0-03ad-4f08-8010-3aee852c9560    2704    Saddle Club 3 Days Pass - Adult 13+ (20% Discount)      1523.80952      f       \N      \N      f       0
8c7b139c-17c0-4b52-84f2-3a731c85212f    2411    Security guard  350     f       \N      \N      f       0
5a5d03af-2b84-44cd-93f1-5530264df758    452     ClinicMAT -DIPROFOS INJ. AMP 2ML        26      f       1       \N      f       25.9985
69599e02-8284-4221-8ec3-416bc8f38bf7    411     ClinicMAT -DMSO 73.5    f       1       73.5    f       73.5
296a2ebc-b376-4125-b0a7-6d29dfae4007    432     ClinicMAT -Datamars Microchip Transponders      78.75   f       1       78.75   f       78.75
0f6a0628-7d3b-406c-8dad-81195283b07a    2027    ClinicMAT -Dental mirror        225     f       1       225     f       225
56a71eef-b3b8-431a-bc99-9957782b4d28    287     ClinicMAT -Dermapred Ointment   122.83  f       1       122.83266667    f       122.83272727272727
d2672769-8460-49f3-8295-2c4857cf01c2    2350    Silicone / Impression Material (Per Hoof)       150     f       \N      \N      f       0
582b92c6-3f15-4e01-b463-529fee411b2f    2516    Specialist Shoe Construction fees       1800    f       \N      \N      f       0
c357e962-db47-4d0e-af93-d16a20d1953f    2838    Splash & party sales    47.61904762     f       \N      \N      f       0
834e3fba-71b3-4363-b437-70f25e506a29    2839    Spring Activation Sales Flowers 47.61904762     f       \N      \N      f       0
8b825513-39f4-4c5d-9d2b-eef88f5fcf0c    2840    Spring Activation Sales_Workshop        47.61904762     f       \N      \N      f       0
63f59f88-e7fd-4eb2-936e-1eabffddfa93    606     StationaryMAT -A3 LAMINATION POUCH      \N      f       \N      28.25   f       28.25
59298b0a-2ac8-4e49-8d6d-4570965730f8    551     StationaryMAT -A3 PHOTO COPY PAPER      \N      f       \N      135.57  f       135
170ed7b8-a819-4cfe-8f7f-b42628df0ce4    552     StationaryMAT -A4 CLEAR SHEET FOR BINDING PKT   \N      f       \N      16.5    f       15.5
eadd69b9-afe3-435d-b642-9f5d42f3bbe7    553     StationaryMAT -A4 DURABLE CLEAR FILE 1X50       \N      f       \N      2.23137143      f       2.231407407407407
7d248735-7695-4d25-a1be-e5480683d36d    2854    StationaryMAT -A4 Envelope ADEC Natural White (Portrait)        \N      f       \N      \N      f       3.35
81c0e0c9-5bf6-4d3a-a6d5-31721846f555    2855    StationaryMAT -A4 Envelope Al Khail Square Natural White (Landscape)    \N      f       \N      \N      f       3.875
3d8e1f88-96fc-4b61-a87f-d5a4a9ee913e    2853    StationaryMAT -A4 Envelope Al Khail Square Natural White (Portrait)     \N      f       \N      \N      f       3.35
e8c55af6-e544-456f-9189-dcf1910ebfe0    2277    StationaryMAT -A4 GOLD DUST 250GSM Paper 1x100  \N      f       \N      125     f       125
bed6221e-d263-4c29-b742-d79cc1251666    2276    StationaryMAT -A4 PAPER CUTTER 15 X 12  \N      f       \N      \N      f       43
8575e9a3-b020-4217-bbc5-3a23ceb4e706    554     StationaryMAT -A4 PHOTOCOPY PAPER       \N      f       \N      66.39333333     f       66.5
b4da6c58-78c7-4d39-be54-1ed7ce1ecd55    2274    StationaryMAT -A4 colour paper 1x500    \N      f       \N      19.5    f       19.5
7a17bdba-dc9e-4b28-875e-57b39dfb4b6d    625     StationaryMAT -ADEC BLUE FOLDER \N      f       \N      3.7     f       3.7
cd5890fa-fc05-45e9-87f3-7e4b04427e70    608     StationaryMAT -ADEC ENVELOP MEDIUM SIZE \N      f       \N      2.28732222      f       8.333333333333332
591eebbb-53b3-4bf6-803b-67630629e113    584     StationaryMAT -ATLAS STAPLE PIN SIZE: 13/6 MM   \N      f       \N      15      f       15
2f32e948-54fd-44cd-a9b0-d9f67a9cd855    589     StationaryMAT -BINDER CLIP 1" (25 MM)   \N      f       \N      14.175  f       14.176666666666668
398954a7-3d7e-4b5e-983b-d750da8de55b    590     StationaryMAT -BINDER CLIP 1.1/4" (32 MM)       \N      f       \N      20.16   f       20.16
d7e3a68d-2bb7-4774-8dfa-f28c7d382132    630     StationaryMAT -BINDER CLIP 15mm \N      f       \N      8.82    f       8.82
6aa26320-33c9-48f9-b5ec-3e0597e67855    592     StationaryMAT -BINDING STICK    \N      f       \N      121     f       121
3d43f5df-85b7-4ba3-a935-a6ed95a3fc2e    556     StationaryMAT -BOX FILES ALBA RADO      \N      f       \N      3       f       3
49171411-481a-49e8-a27f-2dd3b6f14f69    557     StationaryMAT -BROTHER TONER TN 6600    \N      f       \N      382     f       382
793a55cb-8359-409a-951a-0c98fb6f30bb    607     StationaryMAT -BROWN PACKING TAPE 2"    \N      f       \N      1.84265306      f       1.75
362183f9-8a50-43b0-815a-7ae0f1126e64    2616    StationaryMAT -Binding Sheet 230GSM, A4, White 100 SHEETS       \N      f       \N      11.25   f       11.25
621bf96c-7834-4a61-9ce6-92db60191898    602     StationaryMAT -CALCULATOR       \N      f       \N      29.08333333     f       29.5
74b874ff-1b83-46e5-bd0c-2488c121cce6    2660    StationaryMAT -CANNON PRINTER TONER C-EXV 47 BLACK      \N      f       \N      225     f       225
455d624f-7e77-4403-bd93-70422b2bb089    2661    StationaryMAT -CANNON PRINTER TONER C-EXV 47 CYAN       \N      f       \N      310     f       310
b63a4244-fd64-41fb-8421-5ac3522268d8    2662    StationaryMAT -CANNON PRINTER TONER C-EXV 47 MAGENTA    \N      f       \N      310     f       310
ef7b005e-0e70-4a2f-a21b-d1b595041735    2663    StationaryMAT -CANNON PRINTER TONER C-EXV 47 YELLOW     \N      f       \N      310     f       310
fae07c38-2170-4bde-be68-69fa118c4494    2820    StationaryMAT -CANNON PRINTER TONER C-EXV 51 BLACK      \N      f       \N      410     f       410
4b7c3e97-29ba-4d8e-968e-f7b5f51a811c    2821    StationaryMAT -CANNON PRINTER TONER C-EXV 51 CAYAN      \N      f       \N      490     f       490
21c04d70-0268-4b7d-9a2e-eb288b8e9bd5    2823    StationaryMAT -CANNON PRINTER TONER C-EXV 51 MAGENTA    \N      f       \N      490     f       490
1c2dacbb-6011-4007-9b63-9aa3fe653ad8    2822    StationaryMAT -CANNON PRINTER TONER C-EXV 51 YELLOW     \N      f       \N      490     f       490
209b996d-89a1-4ab0-bf59-106748478c3c    558     StationaryMAT -CANON NPG II TONER       \N      f       \N      145     f       145
6a2502b1-cf14-4022-8e74-f63b9711ca2c    641     StationaryMAT -CARTRIDGE FOR CASIO CALCULATOR DR-240 HT \N      f       \N      7.5     f       7.5
db612c3a-8ebb-43fd-a940-053ba78b7f41    636     StationaryMAT -CD POUCH – PKT   \N      f       \N      8       f       8
25929043-cd4f-488c-bd71-30a7fdbf5b7d    591     StationaryMAT -CD/ DVD MARKER   \N      f       \N      0.95    f       0.95
87cc38e6-a474-48fb-988b-94434fc549b9    559     StationaryMAT -CD/R 1 X 100 PKT \N      f       \N      55      f       55
641b424c-a9fd-4776-b3f4-d776211bfcaa    555     StationaryMAT -CELLO BALL PENS PKT      \N      f       \N      0.55076923      f       0.61
1aeeab9a-d25a-42fd-b204-7bf288f88614    2417    StationaryMAT -CLIP BOARD A4 SIZE       \N      f       \N      4.25    f       3.75
512b5d12-a6c1-4df4-978a-5a9c4bcaf1f9    632     StationaryMAT -CLIP BOARD A5 SIZE       \N      f       \N      6       f       6
433eb46a-3b9b-4ab2-954d-549c6a1abf6c    560     StationaryMAT -COMPUTER PAPER 4 PLY     \N      f       \N      294     f       294
145e12d1-7fb6-462a-af71-e8802fd6e0aa    561     StationaryMAT -CORRECTION PEN   \N      f       \N      0.90875 f       0.9
74f061c9-5dc3-4b7b-9234-71ec5ea3f8e8    653     StationaryMAT -D RING FILE MULTICOLOR   \N      f       \N      5.5     f       5.5
fc100840-9c17-415f-8b2a-e138c8bae325    615     StationaryMAT -DESK ORGANISER   \N      f       \N      16.5    f       16.5
6892e5e8-3597-45c9-89f1-9679ea332ec5    626     StationaryMAT -DEVELOP TONER TN-213 CYAN        \N      f       \N      422     f       422
734cf8a9-e151-4cea-87d0-81959a29da7b    628     StationaryMAT -DEVELOP TONER TN-213 MAGENTA     \N      f       \N      422     f       422
ec6cc94c-34f4-4559-8941-8aec7653885c    627     StationaryMAT -DEVELOP TONER TN-213 YELLOW      \N      f       \N      422     f       422
10b9f609-9c43-41ab-9d2f-7ab38fce8496    562     StationaryMAT -DOUBLE CLIPS 1X10        \N      f       \N      7       f       7
c8e7fa36-bc41-4ad9-89c3-33c9e895e021    563     StationaryMAT -DOUBLE SIDED TAPE        \N      f       \N      13.775  f       12.25
14cdef10-bffc-432f-9bbe-c1ab83b81fe6    2418    StationaryMAT -DUCT TAPE BLACK 2"       \N      f       \N      5.64909091      f       5.65
6508c8ca-cb41-4a22-9fbd-b7df77677f35    609     StationaryMAT -DVD DISC \N      f       \N      0.77    f       0.77
6e48dc36-bacc-422a-bb11-69b8ba1bb5a1    565     StationaryMAT -ENVELOPES A3 250'S       \N      f       \N      \N      f       0.75
354922a2-2a11-4565-85c3-45ad6458f7fb    566     StationaryMAT -ENVELOPES WHITE A4 W/ ADEC LOGO  \N      f       \N      0.53632 f       0.53632
ecc29dbd-43ac-41dc-b208-3f96860d3427    2123    StationaryMAT -ENVELOPES WHITE SMALL 1X250      \N      f       \N      0.10031 f       0.055
aa1dd700-4c76-4189-8718-788113724bdb    621     StationaryMAT -EPSON RIBBON LQ-690      \N      f       \N      29.74   f       29.74
328d93f2-f3a4-4cc4-89d3-1bc569975a08    567     StationaryMAT -ERAZER   \N      f       \N      0.5235  f       0.5
23a2f5cb-bd93-4a76-b7f5-c6abe2c7f5d1    680     StationaryMAT -FILE DIVDER COLORED      \N      f       \N      28.74   f       28.74
4b3c59f4-85ec-4fff-8229-a8b5703e4742    2120    StationaryMAT -FILE FASTNERS    \N      f       \N      2.87    f       2.87
484a4e58-a068-4c70-b471-0164a8303870    533     StationaryMAT -HANGING FILES 1X50       \N      f       \N      50.35333333     f       50.35333333333333
f9136566-c182-4245-a23a-48b079d84da2    631     StationaryMAT -HEAVY DUTY STAPLER WITH STAPLES PIN      \N      f       \N      90      f       90
bfdc1bcf-344a-49cd-8bf9-22c41d0b0364    624     StationaryMAT -HIGH LIGHTER     \N      f       \N      0.67129032      f       0.65
ce473c58-73d2-40bc-ba8e-7002be99f954    670     StationaryMAT -HP 410A Black Original LaserJet Toner Cartridge, CF410A  \N      f       \N      385     f       385
df47e14a-0076-4535-b65a-6f4f6e4a2396    673     StationaryMAT -HP 410A Magenta Original LaserJet Toner Cartridge, CF413A        \N      f       \N      424.5   f       444
d7418f3f-6821-4bca-bb82-e2edf6baeadd    671     StationaryMAT -HP 410A Yellow Original LaserJet Toner Cartridge, CF412A \N      f       \N      485     f       485
ca2efc04-60a2-4adb-be53-e3e6c23bb19d    672     StationaryMAT -HP 410A cyan Original LaserJet Toner Cartridge, CF411A   \N      f       \N      485     f       485
f3d84782-b624-461f-908f-e5af29abf39e    593     StationaryMAT -HP CARTRIDGE TONER 4050T \N      f       \N      377.5   f       377.5
b9a27872-be29-46ad-8589-4479a1d70e07    585     StationaryMAT -HP CATRIDGE TONER-NO. CC530A     \N      f       \N      221.45  f       221.45
b466a4e8-af78-471e-8668-80d4421ae058    586     StationaryMAT -HP CATRIDGE TONER-NO. CC531A     \N      f       \N      241.45  f       241.45
a556b6ea-dad2-43fb-b0e6-fd852c65696a    588     StationaryMAT -HP CATRIDGE TONER-NO. CC532A     \N      f       \N      229.2   f       229.2
ad961b15-241e-4a51-9873-3082a069e189    587     StationaryMAT -HP CATRIDGE TONER-NO. CC533A     \N      f       \N      239.3   f       239.3
61cd2fc1-ddc7-40e1-a40f-ac451e283d4c    599     StationaryMAT -HP COLOR LASERJET CP3525n CE251A \N      f       \N      736.25  f       736.25
72c8ccf7-2aa2-4e52-b40e-727c05d50e02    601     StationaryMAT -HP COLOR LASERJET CP3525n CE252A \N      f       \N      777.78  f       777.78
ac69b069-e2d5-4795-a4bd-ed3b3e775da1    600     StationaryMAT -HP COLOR LASERJET CP3525n CE253A \N      f       \N      736.25  f       736.25
9ff22258-61f5-41ce-95ad-bec01f7e9023    576     StationaryMAT -HP DESKJET F2483 BLACK   \N      f       \N      23.8    f       23.8
61ba8b62-a1a4-4dcb-b7ac-c29d344f44d5    575     StationaryMAT -HP DESKJET F2483 COLOR   \N      f       \N      48      f       48
557d171b-43b9-42af-8dbc-346569062531    637     StationaryMAT -HP LASER JET TONER CF380A BLACK  \N      f       \N      39.37   f       39.37
2b602cec-6eb1-4618-8ba4-a791be37a0a4    638     StationaryMAT -HP LASER JET TONER CF381A CYAN   \N      f       \N      102.1   f       102.1
28837cef-c199-4530-b899-4ca827991283    640     StationaryMAT -HP LASER JET TONER CF382A YELLOW \N      f       \N      144.97  f       144.97
03d2c186-819c-415d-9fb5-948c0291f9f0    639     StationaryMAT -HP LASER JET TONER CF383A MAGENTA        \N      f       \N      123.53  f       123.53
64b8764f-5959-4039-8138-f848da4413fe    579     StationaryMAT -HP LASERJET 1300 CARTRIDGE TONER \N      f       \N      282.5   f       282.5
447ba036-7d17-4e05-bac3-be49b9ce198a    594     StationaryMAT -HP LASERJET 1320 CARTRIDGE       \N      f       \N      325     f       325
225e547e-bd69-495f-8e3d-36b122a446f2    595     StationaryMAT -HP LASERJET 2840 TONER Q3960A    \N      f       \N      296.66666667    f       296.6666666666667
91b3f026-814e-4114-8316-0c664df5107a    596     StationaryMAT -HP LASERJET 2840 TONER Q3961A    \N      f       \N      358.33333333    f       358.3333333333333
077025d8-39c4-4e53-a490-6fb9dc418fad    597     StationaryMAT -HP LASERJET 2840 TONER Q3962A    \N      f       \N      358.33333333    f       358.3333333333333
a88c7ea1-0796-4d02-8d6b-97bbdc9602c3    598     StationaryMAT -HP LASERJET 2840 TONER Q3963A    \N      f       \N      358.33333333    f       358.3333333333333
39682c5e-9c0c-46e8-ab44-2218d37d0758    685     StationaryMAT -HP LASERJET TONER 207A BLACK     \N      f       \N      220.335 f       220.334
97df741a-c723-4b84-a81f-aec1a081b5c4    686     StationaryMAT -HP LASERJET TONER 207A CYAN      \N      f       \N      257     f       257
d2928dc6-eb0e-4761-89f3-b8e3f0475991    688     StationaryMAT -HP LASERJET TONER 207A MAGENTA   \N      f       \N      257     f       257
86c6d6c6-435d-42c4-a5a0-3546a00baf79    687     StationaryMAT -HP LASERJET TONER 207A YELLOW    \N      f       \N      257     f       257
63f78cc0-1264-4ce6-b9e8-abdf2b3438f7    2529    StationaryMAT -HP LASERJET TONER W2220A-BLACK   \N      f       \N      239.5   f       244
826ea7fb-2d98-498a-8763-859d863ff3d8    2530    StationaryMAT -HP LASERJET TONER W2221A- CYAN   \N      f       \N      268.89  f       284
5732f165-ecbe-4c8b-b233-9bf940829125    2532    StationaryMAT -HP LASERJET TONER W2222A-YELLOW  \N      f       \N      262.66666667    f       284
6863c8c4-3d20-4f03-8970-9b4b62437a95    2531    StationaryMAT -HP LASERJET TONER W2223A-MAGENTA \N      f       \N      267     f       284
c0c0413d-4578-41cf-b5df-6913aad7e3d2    2382    StationaryMAT -HP LESER JET (W2030A) 415A BLACK \N      f       \N      303     f       307
050146c7-3739-4721-9434-4cf76fea5dce    2383    StationaryMAT -HP LESER JET (W2031A) 415A CYAN  \N      f       \N      393     f       397
666ee1f1-ef9c-449a-a9f1-b7471bc95665    2384    StationaryMAT -HP LESER JET (W2032A) 415A YELLOW        \N      f       \N      393     f       397
73608c6f-73e1-4292-9578-c20cea4c6a63    2385    StationaryMAT -HP LESER JET (W2033A) 415A MAGENTA       \N      f       \N      393     f       397
b20e503e-ad67-4416-9e7a-b6ebc2135296    2672    StationaryMAT -HP TONER  CYAN – (130A)  \N      f       \N      236     f       236
f7ffe0b9-bb36-4ef3-9ce2-808b3d4e15ee    2668    StationaryMAT -HP TONER  CYAN – (216A)  \N      f       \N      227     f       227
2fd7d180-58fa-4a89-8dee-ee4649aa3f39    2670    StationaryMAT -HP TONER  YELLOW –  (216A)       \N      f       \N      227     f       227
e7d47182-9f23-49c2-ac1b-311c8db35f79    2757    StationaryMAT -HP TONER 117A BLACK W2070        \N      f       \N      182     f       182
cfd1f9a2-fb64-4051-a5a9-018b33fc1993    2758    StationaryMAT -HP TONER 117A CYAN W2071 \N      f       \N      195     f       195
741e6315-a964-4cab-aab4-9ecc2545abeb    2760    StationaryMAT -HP TONER 117A MAGENTA W2073      \N      f       \N      195     f       195
6084ae5b-b09a-442c-a1e1-f0b160ce6724    2759    StationaryMAT -HP TONER 117A YELLOW W2072       \N      f       \N      195     f       195
a6564c5c-246a-47c4-8c34-4f2b3c6a396d    643     StationaryMAT -HP TONER 201A (CF400A) BLACK     \N      f       \N      262     f       262
31178fba-c36b-4eae-827a-7b12b64d0795    644     StationaryMAT -HP TONER 201A (CF401A) CAYAN     \N      f       \N      267     f       267
fb3cdb66-95b7-4d59-bec3-7488322a0b22    645     StationaryMAT -HP TONER 201A (CF402A) YELLOW    \N      f       \N      271.48666667    f       271.4875
ac5848dc-df12-4bfa-82af-71854fd3a7b6    646     StationaryMAT -HP TONER 201A (CF403A) MAGENTA   \N      f       \N      267     f       267
67a22096-5d7e-4a7e-8f90-c010555e5ed6    659     StationaryMAT -HP TONER 203A BLACK      \N      f       \N      225.44  f       234
0feef0ba-1b47-4a42-9cb1-63a83ef32dbc    660     StationaryMAT -HP TONER 203A CAYAN      \N      f       \N      259.655 f       268
4e91b347-f220-4dad-957d-f333dd003abc    662     StationaryMAT -HP TONER 203A MAGENTA    \N      f       \N      259.4225        f       268
725882b8-bfec-466d-9927-f0b71def0a08    661     StationaryMAT -HP TONER 203A YELLOW     \N      f       \N      260.5775        f       268
a41f2f3c-3aaf-47f4-98fa-6e8dd54a4f57    611     StationaryMAT -HP TONER 51A LASERJET P3005      \N      f       \N      419.83333333    f       419.8333333333333
1f4e3ad1-21e6-41a8-a863-f7f5dbc3fbd6    647     StationaryMAT -HP TONER 970XL BLACK     \N      f       \N      300     f       300
0edd6ede-51d7-4e41-808d-d73af98ec563    648     StationaryMAT -HP TONER 971 CAYAN       \N      f       \N      210     f       210
d45cb352-f259-4232-aea1-06b5b59f217e    650     StationaryMAT -HP TONER 971 MAGENTA     \N      f       \N      210     f       210
f79b2bf8-6fba-4d3b-8751-02bdd9f4ea68    649     StationaryMAT -HP TONER 971 YELLOW      \N      f       \N      210     f       210
8336b20f-51a9-4698-9ac6-65ada9272160    2650    StationaryMAT -HP TONER BLACK 131A      \N      f       \N      299     f       299
701334d2-00c9-402c-a67b-7502edb22c0f    2671    StationaryMAT -HP TONER BLACK – (130A)  \N      f       \N      236     f       236
33b3a860-0324-4f52-ba0b-1c593ac2c91b    2667    StationaryMAT -HP TONER BLACK – (216A)  \N      f       \N      212     f       212
2be312cb-a79e-446d-ab95-cf5808025f81    2550    StationaryMAT -HP TONER BLACK – (53A)   \N      f       \N      312     f       312
903f66d7-3abc-4efd-acb0-3633837bc250    2542    StationaryMAT -HP TONER BLACK – (953XL) \N      f       \N      205     f       205
701da67d-b701-4d24-96be-ed9f8e238fac    2546    StationaryMAT -HP TONER BLACK – 205A    \N      f       \N      \N      f       208
728d076d-08ab-4b26-b5f6-a7daac132fe3    2651    StationaryMAT -HP TONER CYAN 131A       \N      f       \N      382     f       382
8cc18476-c3a8-440b-991c-c8ee1a92ff7c    2543    StationaryMAT -HP TONER CYAN – (957XL)  \N      f       \N      142     f       142
0e64bc45-e94d-463b-9bd1-844c7975c77c    2547    StationaryMAT -HP TONER CYAN – 205A     \N      f       \N      213     f       209
c4f48344-33bb-4f97-b07c-845bab6aeaea    2673    StationaryMAT -HP TONER MAGENDA – (130A)        \N      f       \N      236     f       236
907c1dc3-0ce3-4112-9c7c-422e6036c4c7    2669    StationaryMAT -HP TONER MAGENDA – (216A)        \N      f       \N      227     f       227
07a1ea85-624b-4825-aab7-fd11f480c805    2652    StationaryMAT -HP TONER MAGENTA 131A    \N      f       \N      382     f       382
bc11c06e-67df-446a-a892-e28452251671    2544    StationaryMAT -HP TONER MAGENTA – (957XL)       \N      f       \N      142     f       142
37a1dce0-f38d-462b-be33-82bfb3bbdf56    2548    StationaryMAT -HP TONER MAGENTA – 205A  \N      f       \N      213     f       209
91b112f8-0d05-4fb1-af1c-d24588a6874b    2653    StationaryMAT -HP TONER YELLOW 131A     \N      f       \N      382     f       382
82c5124d-178e-41a6-b738-bb0aaf8e2dd5    2674    StationaryMAT -HP TONER YELLOW –  (130A)        \N      f       \N      236     f       236
a435ea43-e1b8-4d85-ae04-ae2a20c04e21    2545    StationaryMAT -HP TONER YELLOW – (957XL)        \N      f       \N      142     f       142
592cf3e5-77ef-48de-a681-70a1b3277a7f    2549    StationaryMAT -HP TONER YELLOW – 205A   \N      f       \N      213     f       209
42054bdd-92df-481a-8173-591a80282d73    2271    Hostess \N      f       \N      \N      f       \N
9a50dd8f-b524-407b-b245-66d2a59bd6a9    2073    MaintenanceSRV-FUEL EXPENSES    \N      f       \N      0       t       \N
d631d30a-feb9-4ac1-b73a-638f79ee704e    654     StationaryMAT -HP laser jet 500 Toner – M551 BLACK      \N      f       \N      490     f       490
0a8595e6-4be4-4b13-94dc-593deba130a8    657     StationaryMAT -HP laser jet 500 Toner – M551 CYAN       \N      f       \N      700     f       700
d3f21ae9-ca68-43c7-a5a1-2734f9ff0300    656     StationaryMAT -HP laser jet 500 Toner – M551 MAGENTA    \N      f       \N      700     f       700
5a3e563f-c48b-44ab-8649-35f24d4ef83d    655     StationaryMAT -HP laser jet 500 Toner – M551 YELLOW     \N      f       \N      700     f       700
c7d3b278-f87b-46a1-9a79-e3e983355201    2807    StationaryMAT -ID Card Holder - Modest MS73855x85mm     \N      f       \N      1.75    f       1.75
acc3e659-6c31-441a-8cec-c08358ba672c    652     StationaryMAT -KEY TAG PLASTIC  \N      f       \N      13.12666667     f       13.125
3644d1ec-3f41-43fb-9931-543a53a54d40    675     StationaryMAT -KYOCERA TONER TK-8115 BLACK      \N      f       \N      252     f       252
421852c4-95b3-44d7-b6cb-3b1f28951ac7    678     StationaryMAT -KYOCERA TONER TK-8115 CYAN       \N      f       \N      242     f       242
bb2ed366-02ed-4271-a946-ac3859a1f746    676     StationaryMAT -KYOCERA TONER TK-8115 MAGENTA    \N      f       \N      242     f       242
688e8316-190d-4865-8cba-de3f2cb8ea8a    677     StationaryMAT -KYOCERA TONER TK-8115 YELLOW     \N      f       \N      242     f       242
51b7bb57-f3c6-4363-a4b1-673cb3a496cc    689     StationaryMAT -Kyocera TK-8365K Toner BLACK     \N      f       \N      274     f       328
b124f309-4b54-474d-862b-8d09aa94a495    690     StationaryMAT -Kyocera TK-8365K Toner CAYAN     \N      f       \N      327     f       327
956389f3-aadd-44c8-a717-336be89227ac    692     StationaryMAT -Kyocera TK-8365K Toner MAGENTA   \N      f       \N      327.5   f       328
30018868-9de7-48a2-9968-77e40cfd8667    691     StationaryMAT -Kyocera TK-8365K Toner YELLOW    \N      f       \N      328     f       328
f0f0d512-ca73-4202-93a1-c1ec806f5724    604     StationaryMAT -LABELS MULTI PURPOSE     \N      f       \N      18.99   f       18.99
0abf90b6-4eb2-49d9-8f11-985ac270bcf5    534     StationaryMAT -LAMINATION POUCH A4 SIZE \N      f       \N      14.4775 f       13.25
e2863124-b211-47d0-9cbd-86c07bf70cfd    635     StationaryMAT -LEAFLET A4 SIZE  \N      f       \N      0.5     f       0.5
11af79b5-8e1c-4296-8f29-b8e70679b7ad    535     StationaryMAT -LETTER HEAD ADEC 100GSM CONQ.BRILLIANT WHITE PAID PAPER  \N      f       \N      1.62761 f       2.4
f861d828-3642-4fe5-b717-b483525ca41b    622     StationaryMAT -LETTERHEAD SHEIKH A4 Paper 100gsm Keycolour Recycled 1x500       \N      f       \N      0.85    f       0.85
8e25fd1f-cf14-4652-a1a2-7503c1dc5bac    537     StationaryMAT -LEXMARK CARTRIDGE        \N      f       \N      102.9   f       102.9
477cbfc2-cdcb-4f09-b4ab-c29b2f6b4470    2199    StationaryMAT -Lamination machine  A3 DSB 330ARP        \N      f       \N      \N      f       675
62c88e54-af76-4fea-8ebd-30cdc5057bf8    2808    StationaryMAT -Lanyard with Hook and Full Printing      \N      f       \N      7.75    f       7.75
fe427d55-84cf-4e4d-8c55-011e69200ac5    2852    StationaryMAT -Letter Head A4 Size ADEC Natural White   \N      f       \N      \N      f       0.7
c256aa81-4fe5-4b12-a631-ff1a3db89de4    2851    StationaryMAT -Letter Head A4 Size Al Khail Square Natural White        \N      f       \N      \N      f       0.7
a80627f5-737b-4d41-855f-ded44fadf0c6    539     StationaryMAT -MASKIN TAPE 1"   \N      f       \N      2.75    f       2.75
eb749318-e2ac-435e-8cff-f080e13253e9    623     StationaryMAT -MASKIN TAPE 2”   \N      f       \N      2.25    f       2.25
418db62f-fbb8-4f6e-b8e6-8aec54823ec8    666     StationaryMAT -MEMO PAD HOLDER  \N      f       \N      4.105   f       4
1dffe489-e385-4851-b986-87fc09aa0a44    620     StationaryMAT -METAL RULER 30CM \N      f       \N      2.25125 f       2.25
7a0fe458-7d21-4287-bc46-ba8dbce6f784    658     StationaryMAT -MOUSE PAD        \N      f       \N      16.33   f       16.33
16b6a3eb-697e-45bc-921c-efb8586a3844    2809    StationaryMAT -Metal Badge Reel with Epoxy Printing     \N      f       \N      7.5     f       7.5
bc9aedd1-4879-4156-a897-247eaf089ebc    540     StationaryMAT -NAME PLATE HOLDER        \N      f       \N      6.02764706      f       6.027714285714286
7c22ec5f-aff6-480c-a0bb-7a6ca000a383    634     StationaryMAT -NOTE PAD A5 SIZE \N      f       \N      4.65    f       4.65
fc870772-1d8b-48e0-bd0c-7fb127de5547    679     StationaryMAT -PACKING TAPE CLEAR       \N      f       \N      1.75    f       1.75
681dc54e-d2ca-46ec-aefc-8b2566e72cc9    541     StationaryMAT -PANASONIC TONER FA57A    \N      f       \N      79      f       79
d5dff70a-7537-4f05-9848-ad5a2580b15f    2561    StationaryMAT -PAPER BAG TURF CLUB      \N      f       \N      \N      f       19
f2241e44-1b3d-49fa-95ee-232446a36540    542     StationaryMAT -PAPER CLIPS      \N      f       \N      12.25   f       12.25
e1e62929-4b19-4218-8a3a-193f90ed2cbf    668     StationaryMAT -PAPER TRAY MESH  \N      f       \N      16.26714286     f       16.25
837819f9-0d00-4dd3-9fea-1dfe8583db03    610     StationaryMAT -PAPERBAG BLUE    \N      f       \N      4.28    f       4.28
31b6bd4e-2c4c-495a-af21-39f77ccec886    667     StationaryMAT -PEN RACK (PEN HOLDER)    \N      f       \N      1.81875 f       1.75
3ac9bcf7-82e0-4c51-9dba-88f5ef41081c    543     StationaryMAT -PENCIL   \N      f       \N      0.53794643      f       0.585
934539c7-1d3d-4b0c-99a8-8a46dcfdeef1    651     StationaryMAT -PHOTOGLOSSY PAPER A4     \N      f       \N      16.0875 f       16.0875
c46a2acc-8feb-4ab0-a535-7ca86768e05c    669     StationaryMAT -PIN HOLDER(CLIP DISPENSER)       \N      f       \N      3.25    f       3.25
211dab6f-810d-4951-97bb-481d7782a3aa    616     StationaryMAT -PINS OFFICIAL    \N      f       \N      4.5     f       4.5
6ad0f2a5-affa-4423-9aa6-d89f02bb2b55    629     StationaryMAT -PLASTIC CLEAR SHEET (FILE DIVIDER)       \N      f       \N      \N      f       10.5
9db5b2f2-75be-4e5a-9c68-72aa19bfdfeb    583     StationaryMAT -PLASTIC FILE RACK        \N      f       \N      8.4     f       8.4
3b4fa25f-b457-43f2-86ec-3d38b10e3209    577     StationaryMAT -POST IT SIGN HERE STICKER        \N      f       \N      6.0516  f       6.051379310344828
985a949e-cd25-4c8d-a1ff-274d2820008c    545     StationaryMAT -POST IT YELLOW PAD       \N      f       \N      2.6875  f       1.49
ef46836c-602e-48dc-95c2-faaf8807e6ab    664     StationaryMAT -POST IT YELLOW PADS 1.5x2”       \N      f       \N      0.7     f       0.7
179c8cd2-e034-4ea1-b9ca-5c3c0d6153ba    665     StationaryMAT -POST IT YELLOW PADS 3x3” \N      f       \N      0.95    f       0.95
785b3f64-c5b0-4baf-a0bb-8b8d9d03cdcc    546     StationaryMAT -PRINTING OF BOOKLET BROCHURE S/J \N      f       \N      2.75    f       2.75
eca58e25-ed99-4d38-b265-9dda1b5dde5d    547     StationaryMAT -PUNCHING MACHINE \N      f       \N      92      f       92
ab9e92bb-3572-48f5-9a2b-6104be90c1ba    2122    StationaryMAT -PUSH PIN \N      f       \N      1.576   f       1.575
6bde5abe-89bd-4b66-8a10-0edf5c69eee4    2806    StationaryMAT -PVC Card with Printing on 2 sides Size: 8.4cm x 5.4cm    \N      f       \N      6       f       6
ed334d67-6091-49ad-a68e-06b623e4962f    2541    StationaryMAT -REGISTER BOOK 10x8 4QR   \N      f       \N      6.48363636      f       6.25
8fee2666-29fc-4a2c-95b4-9844d4bf3305    2266    StationaryMAT -REGISTER BOOK 2QR        \N      f       \N      \N      f       6.75
805046f3-1980-49f8-ac0c-0f60cfabfaf6    642     StationaryMAT -RICOH - TONER MP 4500E COLOR BLACK       \N      f       \N      221.67  f       221.67
17f63f00-0cde-4cab-a58c-2f0d426aa91f    613     StationaryMAT -RICOH TONER 1230D (PRINTER RICHO 2120)   \N      f       \N      135     f       135
ef3348db-257e-464e-b7cf-fa2b3501939e    617     StationaryMAT -RIGID CLOSED BOX FILE    \N      f       \N      9.25    f       9.25
19fc71d8-76d5-4104-b74f-04b4ceca59fb    633     StationaryMAT -ROLLING SLICER CUTTER BLADE      \N      f       \N      15      f       15
731a0bd6-b9a0-4f13-8719-a70e2d7dbbf7    582     StationaryMAT -RUBBER BOND      \N      f       \N      3.45    f       3.45
d029b55f-7b17-4f38-9838-f4cb6752ec52    548     StationaryMAT -SCISSCORS        \N      f       \N      2.96181818      f       2.95
b440bcea-a674-42b1-8962-77ee3c73a766    578     StationaryMAT -SCOTCH TAPE SMALL        \N      f       \N      4.72652174      f       6.45
3e8bca5c-c49c-4865-b2a3-02875b7ba6a8    549     StationaryMAT -SHARPNER PENCIL  \N      f       \N      1.485   f       1.485
e4814590-8731-4c27-bbe1-cdd975cbae37    674     StationaryMAT -SHREDDER MACHINE \N      f       \N      \N      f       650
3485ae1a-6142-4a6a-a1c1-6698f6484120    605     StationaryMAT -SMALL LAMINATION POUCH   \N      f       \N      7.565   f       7.565
d1ff9d41-fca0-4cb6-8636-19611e0a338f    614     StationaryMAT -SMALL PAPER PUNCH        \N      f       \N      7.5     f       7.5
d931d4f3-bb3b-4f4a-b36e-417e219569b0    2419    StationaryMAT -STAPLE PIN SIZE: 26/6 20/BOX     \N      f       \N      10.5    f       10.5
3752a2dd-4faf-440d-ab2a-7d28f00f0c3f    568     StationaryMAT -STAPLER MACHINE SIZE 26/6        \N      f       \N      5.92461538      f       5.95
f67b8ab6-0938-4802-a7a7-07792374bb60    570     StationaryMAT -STAPLER REMOVER  \N      f       \N      2.04285714      f       1.75
3e9598ac-4a38-4c11-b1f9-2ca9d6b49b39    427     ClinicMAT -Dermoline Shampoo 5ltr       \N      f       1       \N      f       100
0a5d3d3d-41ff-4d88-82f2-178d10207eca    612     StationaryMAT -STAPLES HD 110 SHEET 55-23/13H   \N      f       \N      6.5     f       6.5
e2496772-ba7e-493f-b298-e06a6524c6ee    2275    StationaryMAT -Safety pins 1x400        \N      f       \N      10.5    f       10.5
00fb3468-0c7a-45e3-9996-bf8ed5897033    603     StationaryMAT -TELEPHONE DIARY  \N      f       \N      12.67   f       12.67
b02a8cc6-fdbe-4c9c-bdd1-1c76d7bf6e1e    571     StationaryMAT -TYPEWRITER RIBBON ET 2400        \N      f       \N      45.75   f       45.75
6ab6f540-be4c-4da5-aa58-0ac0e04646e8    572     StationaryMAT -TYREEK PAPER WITH PRINTING       \N      f       \N      1.25    f       1.25
f8b992bf-4790-4ed1-bc29-abe8f7914711    2843    StationaryMAT -Thermal Rolls 80x80mm (1X50 Roll/Box)    \N      f       \N      \N      f       95
aa02f19b-675e-4ae1-bc41-9f7d1e2deac7    573     StationaryMAT -UHU STICK        \N      f       \N      4.0975  f       4.098333333333333
45403985-e482-45af-ba3e-25d55b1ef556    574     StationaryMAT -UNI BALL PEN     \N      f       \N      3.579   f       3.5792
9018ebcc-60dd-496c-b48f-6bd7d2c97b9f    538     StationaryMAT -WHITE BOARD MARKER PEN   \N      f       \N      0.7     f       0.7
c241f7a8-65e7-4d81-93a7-014d421ba854    684     StationaryMAT -WHITE BOARD WITH MOVABLE STAND – 90X120CM        \N      f       \N      90      f       90
4034c2cc-59d9-4d61-a84e-7766c11ca69e    2617    StationaryMAT -Wire Binding Spines, Metal 34 Teeth Double Ring 100 Packs A4 Paper Size 1/2 Inch \N      f       \N      77      f       77
b036431c-d0ea-4dc6-9013-8e1c45e57cc0    1542    TackMAT - WHEEL BARROW 400L     \N      f       \N      \N      f       3050
68c8ff89-4b16-4d30-afc2-fe9eb498357e    1435    TackMAT -18' GENERAL WHIP       \N      f       \N      \N      f       90
02a5b968-fdb4-4898-b854-3723912b4d3d    1436    TackMAT -ACRLYIC STABLE BANDAGES 1 X 4  \N      f       \N      55      f       55
570c6ba8-3c2e-4618-ad3a-71b4b0a7c1aa    1437    TackMAT -AIGLE JODPHUR BOOT     \N      f       \N      115     f       115
19a4498c-0f6f-45cd-9c81-f724c76adbd3    1438    TackMAT -AIGLE JUMPING BOOT     \N      f       \N      105     f       105
df4ba848-1ba6-48a1-bd8b-50a121891d0f    1439    TackMAT -ALUMINIUM MANE COMB    \N      f       \N      12      f       12
f7b13f92-913f-44d0-afc2-3a6578673835    1441    TackMAT -ANTI GRAZING REINS     \N      f       \N      60.5    f       60.5
8901d516-e48c-4eb3-9f1d-5a25b53cd74f    1442    TackMAT -AUSTRALIAN NOSE BAND   \N      f       \N      20.5    f       20.5
9ae025c9-8303-483c-b476-8867ad6cd994    2131    TackMAT -Argosy Clip    \N      f       \N      \N      f       40
fa901bf0-dae3-411a-81c5-95d3fd2c9680    1583    TackMAT -BEST HOOF GREASE 5 LTR \N      f       \N      \N      f       403.2
57d19308-4d78-4f41-8321-a7b9303b99ae    1444    TackMAT -BIG SPONGES    \N      f       \N      8       f       8
617e478a-bc53-46c4-83ac-82c3590eaa15    1445    TackMAT -BIG TOWEL      \N      f       \N      30.45   f       30.45
472a17f7-81bf-4ae8-a20f-ed64c24d9180    1589    TackMAT -BIT CHAIN SMALL GOLD   \N      f       \N      100     f       100
05e49245-10e2-40c6-b850-ba3a76bf51bb    1446    TackMAT -BIT GUARD      \N      f       \N      29.76277778     f       29.762777777777778
1c666f75-d9c1-49d9-82d3-bd2716624eab    1539    TackMAT -BLACK BUCKET (OLD)     \N      f       \N      25.5    f       25.5
3e839b85-158f-4bef-b6d8-81e6bca60a03    1553    TackMAT -BODY BRUSH     \N      f       \N      \N      f       12
3e42f2ca-2f0e-4dde-9774-3633f2a25e12    1448    TackMAT -BOOT JACK      \N      f       \N      14.5    f       14.5
ca72e20b-92cc-4d60-84a2-f2f7cc104455    1499    TackMAT -BRASS REIN CHAIN       \N      f       \N      22.5    f       22.5
babe4f9e-7837-4ba4-a8ef-3f555bef5901    1588    TackMAT -BRASS REIN CHAIN GOLD LARGE    \N      f       \N      140     f       140
8dd41f49-14a1-461c-8272-2ebcc7184489    1334    TackMAT -BREAKING ROLLER-ELASTIC        \N      f       \N      49.5    f       49.5
01d99ee3-682c-40f4-aef7-c8c084926f7e    1450    TackMAT -BRIDLE CHEEK   \N      f       \N      58.5    f       58.5
5ab18a7a-a07b-4087-83ef-e0f563d5b92b    1451    TackMAT -BRIDLE RACK    \N      f       \N      20.71428571     f       20.714
41d9b616-26c6-45b2-a7fc-cdf7c6f3573d    1335    TackMAT -BROW BAND      \N      f       \N      21.5    f       21.5
ccb88e35-df78-4c1a-ac83-d4bc1a434379    1452    TackMAT -BURGHLEY GIRTH \N      f       \N      85.5    f       85.5
d085ca14-3010-4de1-b66b-ad5474cf19d8    2376    TackMAT -Ballistic Boots        \N      f       \N      \N      f       116
2b7c64f9-c993-4dd2-aa21-26a5b966edcb    1523    TackMAT -CARRIAGE LEATHER SET   \N      f       \N      600     f       600
1be20b3b-4dca-4ae4-ba16-727371607f22    1453    TackMAT -CHAMPION TRAINING MARTINGLE    \N      f       \N      98.5    f       98.5
24dbad42-1085-411d-9e64-1bb5beba2412    1336    TackMAT -CHERRY ROLLER  \N      f       \N      35.5    f       35.5
1d30814f-e65e-4450-835a-7d42c0d1d05e    1516    TackMAT -CLIPPER BLADE HAMPHAR  \N      f       \N      47.22   f       47.22
9c62034f-e341-4a27-8f68-07fd8c61d2f0    2181    TackMAT -CLIPPER BLADE Liveryman        \N      f       \N      \N      f       240
7e97cdfd-4af2-48e2-83c8-b8c6a380e242    1518    TackMAT -CLIPPER BLADE OSTER    \N      f       \N      98.09   f       98.09
34103976-e9f2-4b89-b126-a7744ba1cce0    1344    TackMAT -CLIPPER BLADE SMALL    \N      f       \N      28.31466667     f       28.314666666666668
7dad2c61-b406-446b-904b-24b591981f90    1517    TackMAT -CLIPPER BLADE WOLSELEY \N      f       \N      16.5    f       16.5
41be221d-def2-4b63-94d6-ef34f875a879    1558    TackMAT -CLIPPER MACHINE        \N      f       \N      1049    f       1049
2b1b6eab-acfb-40ae-97f2-32b8fc0c6feb    1455    TackMAT -COLOUR RUBBER GLOVES PAIR      \N      f       \N      \N      f       7.35
bdca8cff-7073-418c-bc7e-1cc4be44e148    1456    TackMAT -CONTINENTAL WEB LUNGE REINS    \N      f       \N      110     f       110
371e5183-2672-4442-bbf0-568eb438cbcc    1458    TackMAT -CORN/FEED SCOOP        \N      f       \N      23.5    f       23.5
3f4c72be-3e2f-4405-80e2-8c34287906f8    2124    TackMAT -CORNER MANAGER FRAME   \N      f       \N      115     f       115
7a2b6a49-5bfc-4b6b-b379-842bd8c0ecce    1459    TackMAT -COTTON FLY WEIL        \N      f       \N      14.4    f       14.4
206ea5f5-e2ab-492a-9a4a-c74465aa5ba1    2379    TackMAT -Covesion Halter W/Eyelet PP Webbing    \N      f       \N      \N      f       72
f5a411ff-2942-46f0-b05a-9408137c81b3    1461    TackMAT -DANDY BRUSH HORSE HAIR \N      f       \N      \N      f       19
17af6dd2-28c5-4740-b284-21e69aa7575b    1462    TackMAT -DANDY BRUSH WITH NYLON BRISTLES        \N      f       \N      \N      f       19
1368ea86-2cb8-4a70-8b8b-2d84ad8a4c74    1463    TackMAT -DRAW REINS-PAIR        \N      f       \N      132.135 f       132.135
60a442d4-7425-4590-99f7-f7757d8d4f4a    1511    TackMAT -DROP NOSE BAND \N      f       \N      18.5    f       18.5
221d028b-729a-46aa-9eb2-cec678879118    2372    TackMAT -Dandy Brush Wooden Backed      \N      f       \N      \N      f       20
554797e9-dbd0-4fec-aaa6-1f65bfaf162b    2559    TackMAT -Dermoline Medicated Shampoo 5ltr       \N      f       \N      100     f       110
e1407c9c-2091-4159-aa72-38881e3df3dd    2040    TackMAT -EAR PLUG FOR HORSE     \N      f       \N      \N      f       26.25
afd783ac-1d4f-4c5e-8c0a-15e71192cd93    1579    TackMAT -EFFAX LEATHER OIL – 5LTR       \N      f       \N      325     f       325
c21857ff-dac1-4677-a3fa-2adf86e583e3    1466    TackMAT -EGG BUTT FULL WT BIT   \N      f       \N      98.5    f       98.5
4f59358d-ba9f-407d-ad2d-23b8e0c4f88d    1512    TackMAT -ELASTIC BANDAGE 1X4    \N      f       \N      40      f       40
109ae4e6-2aa9-4fc1-a3cc-adb4ef9319ad    1467    TackMAT -ELASTIC SIDE REINS-NYLON       \N      f       \N      \N      f       50
4692217c-65aa-4994-9a3b-716260ad3fed    1555    TackMAT -ESKADRON TENDON BOOTS FRONT    \N      f       \N      186.9   f       186.9
e51193e0-5afc-4b0b-bd77-5ff68d2ed5a8    1556    TackMAT -ESKADRON TENDON BOOTS HIND     \N      f       \N      126     f       126
f252d9c7-4a05-4b5c-86ee-ac5f5e4e6575    1345    TackMAT -FACE CLEAN BRUSH       \N      f       \N      3.5     f       3.5
5214e908-7211-4bb0-8e91-ab8cb1de2264    1524    TackMAT -FLY MASK (RUBBER)      \N      f       \N      14.5    f       14.5
5129e3e1-6999-4221-a3aa-f2a1aab94e84    1347    TackMAT -FLY SPRAY BRONCO GOLD 32OZ     \N      f       \N      \N      f       \N
e2525ce6-c22d-473f-8c8f-5fb5451f0d0c    1532    TackMAT -FOUR POCKET NUMNAH     \N      f       \N      19.5    f       19.5
c87b05a1-8c86-4fba-b8fb-008c531efa3f    2318    TackMAT -FREE MAX SADDLE        \N      f       \N      \N      f       450
d870fefa-fe92-4c4a-80ea-58473c9035bf    1513    TackMAT -FRONT ANKLE BOOT       \N      f       \N      89      f       89
bd70b111-5ae5-4e32-bb69-a9e335033bbf    1348    TackMAT -FULL CHECK JOINTED MOUTH BRADOON       \N      f       \N      145     f       145
f3bcea69-12df-4a8b-82de-cd20391e1ff3    1349    TackMAT -FULMER SNAFFLE \N      f       \N      125.5   f       125.5
661404af-8f74-431d-bd2a-192040e910a4    2295    TackMAT -Flag marker set        \N      f       \N      \N      f       35
55063bd2-10c0-4afc-93d9-589dfbccc036    1352    TackMAT -GOGGLES        \N      f       \N      27.28341463     f       27.28341463414634
a5068801-6bcd-47a3-a596-ef3009162ec2    2237    MaintenanceSRV-Mechanical machinery and equipment       \N      f       \N      \N      f       \N
c6259fe1-6114-42b5-b400-f68ecbe58cea    1353    TackMAT -GORRINGE BREECHES      \N      f       \N      95      f       95
2252a24d-4031-4dc2-90ac-8399a769655f    1354    TackMAT -GPA HELMET     \N      f       \N      325     f       325
6c5a86b7-7686-4671-a145-c42d076ec688    2174    OtherSRV-⁠Consumables - IT Supplies     \N      f       \N      0       t       \N
6d8cf137-fdab-4650-a505-54670c592513    2075    OtherSRV-⁠Freelance - Staffing  \N      f       \N      0       t       \N
eaa0f0a8-7053-4744-a3a2-7756c9008b83    1355    TackMAT -GRACKLE NOSE BAND      \N      f       \N      47.89027027     f       47.89027027027027
c1ae1635-4b4d-4b91-8aa7-2b060d3938f9    1356    TackMAT -GROOMING BOX   \N      f       \N      \N      f       175
f61d71df-55f4-47c1-9653-66edb4f8be26    1357    TackMAT -GROOMING GLOVES        \N      f       \N      21.2958 f       12
d6f421a6-3e47-406b-8ede-f8c378fa5f34    1358    TackMAT -HAMPA BOOT PAD \N      f       \N      68.5    f       68.5
1da3a75a-1498-406a-b2ef-380cb44f4193    1359    TackMAT -HAMPA FETLOCK BOOT     \N      f       \N      75.895  f       75.895
7a51f1b6-27ee-4150-a4bf-685fe8759693    1360    TackMAT -HAMPA PROTECTOR        \N      f       \N      85      f       85
8fb930eb-452d-492f-80a3-6659e0fb1ebb    1362    TackMAT -HAY NET        \N      f       \N      \N      f       15.5
30ef1462-cafb-4c8b-92b6-bc22a60568aa    1545    TackMAT -HEAD COLLAR (LEATHER)  \N      f       \N      80      f       80
b9e6e1f3-cf6b-4c9e-b11e-a79538cd1858    1365    TackMAT -HELMET COVER CLOTH     \N      f       \N      61.682  f       61.682
bccbed33-48d0-4163-b6a5-2a13195355df    1592    TackMAT -HESTUR HORSE SHAMPOO 5Ltr      \N      f       \N      \N      f       35.7
bc9884dc-45b0-420b-943b-be067f2c6444    1507    TackMAT -HOOF CLEAN BRUSH       \N      f       \N      7.5     f       7.5
577444b2-baad-4664-9f6c-e62cd5d26b9c    1603    TackMAT -HOOF GREASE 5 LTR.     \N      f       \N      310     f       310
ca657d80-b54d-4892-bd6d-afb12ce08862    2862    TackMAT -HOOF GREASE JOCKEY 1 LTR       \N      f       \N      \N      f       \N
8f7c707c-5da4-4277-bbce-aceb759da621    1366    TackMAT -HORSE BLANKET BLUE COLOUR WITH ADEC LOGO       \N      f       \N      276.31  f       276.31
7138bb3f-3858-4500-841c-257b4fbc4d57    1514    TackMAT -HORSE BLANKET NYLON    \N      f       \N      95.5    f       95.5
41f368dd-09da-461e-87f2-05d857554024    1529    TackMAT -HORSE BLANKET REXINE TYPE      \N      f       \N      75      f       75
9aeb4b27-a305-49a3-bc9d-b0dc63344383    1493    TackMAT -HORSE BOOT FRONT&BACK( SPLINT BOOTS & FETLOCK BOOTS)   \N      f       \N      297     f       297
9a19f039-fae7-493e-822e-8640c2d86a48    1500    TackMAT -HORSE BOOT PAD \N      f       \N      63.83   f       63.83
a09599c9-3b01-4c95-8a76-002dc39d57e0    1343    TackMAT -HORSE PLAYBALL \N      f       \N      65      f       65
9d6eb939-982d-4bf0-93d6-db4bf108315a    1515    TackMAT -HORSE RACE MASK        \N      f       \N      35      f       35
5dab9608-0d0f-437a-a5a3-358675d7aadb    2518    TackMAT -Heiniger Clipper Blades - 31/23        \N      f       \N      150     f       150
e7bb55e0-0ad9-4dce-a581-83d33809e644    2519    TackMAT -Heiniger Clipper Oil Bottle 100ml      \N      f       \N      25      f       25
b85de1ba-f015-4fc8-99d2-e986cb838d7c    2186    TackMAT -Horse Mounting Block   \N      f       \N      \N      f       537.825
089d6516-3cb1-4eea-b55a-3f4cb64524cc    1368    TackMAT -IRISH MARTINGLE        \N      f       \N      115     f       115
e26df065-1ad1-48f4-9457-a813de1ef525    1369    TackMAT -JOCKEY CURRY COMB      \N      f       \N      35      f       35
11280870-6fe8-4ac9-ae55-28051d952677    1370    TackMAT -JOCKEY RACE BOOT       \N      f       \N      205     f       205
1413af33-2761-496c-8069-9b8a4ff4c637    1371    TackMAT -JOCKEY WEIGHT PAD      \N      f       \N      222.5   f       222.5
a20d85c5-c741-4010-8a71-06570ee132d9    1372    TackMAT -JOINTED TOM THUMB      \N      f       \N      105.5   f       105.5
55e34fb4-0ef9-4649-9c29-d1fdf57e415b    1373    TackMAT -KENTUCKY BREECHES      \N      f       \N      95.5    f       95.5
98159a6a-a381-485f-92a6-32bfa01af367    2377    TackMAT -Kimblewick Bit With Curb Chain , Joint Mouth , Size 12Cm/4 3 /4"       \N      f       \N      \N      f       64
cc32dadd-49b6-40e6-ad03-5690d5fb604d    1376    TackMAT -LEATHER ENCK STRAP     \N      f       \N      18.5    f       18.5
44c3f5e0-a1a6-4647-a587-ddc428c3a589    1379    TackMAT -LEATHER LEAD REIN      \N      f       \N      116.43  f       116.43
14791c51-589e-40b7-b9d7-3d6d2d5533e6    1380    TackMAT -LEATHER LUNGING CAVESSION      \N      f       \N      105.07  f       105.07
7a721399-0bb9-47c4-bff8-477313ce9b98    1443    TackMAT -LEATHER MARTINGLE SET  \N      f       \N      \N      f       900
7d35e1ee-857c-4139-a202-2985faeaebea    1381    TackMAT -LEATHER MUZZLE \N      f       \N      75.5    f       75.5
f69eaf02-1754-4bca-8924-9cfd684ecc1d    1382    TackMAT -LEATHER NEW MARKET ATTACHMENT  \N      f       \N      \N      f       60
d8fa83b8-ee8f-4c3f-9ebe-f910e3819022    1385    TackMAT -LEATHER VALUTING ROLLER        \N      f       \N      65.5    f       65.5
6beb91ae-26d3-4f50-963a-ac1c43aab6dd    1496    TackMAT -LONGING WHIP   \N      f       \N      \N      f       45
c24e31d1-38cf-4c1c-aa47-8f2732e8a115    1501    TackMAT -LUNGING ROPE FOR PESSOA        \N      f       \N      \N      f       140
4a826801-b967-4ca4-9cdd-2c6f98fd180f    2132    TackMAT -Leather Running Martingale     \N      f       \N      \N      f       45
2a7bd5c6-f4ed-474c-ae9d-82a85751f917    2133    TackMAT -Leather Draw Rein      \N      f       \N      \N      f       82.5
45dc10a5-cfee-4eb9-aa7c-1277e5a969d3    1520    TackMAT -MARTINGLE NYLON        \N      f       \N      85      f       85
d7ea573e-3c3e-4d09-8996-a7226a01d375    2039    TackMAT -METAL CURRY COMB RUBBER        \N      f       \N      \N      f       7.5
31eb8610-540b-498b-bd72-7a17f9af0e09    1582    TackMAT -METAL SHAVING FORK WITH HANDLE \N      f       \N      147     f       147
53c2b364-6d16-48ea-adad-a60da4240203    1389    TackMAT -MINI CHAPS     \N      f       \N      17.6666 f       17.6666
52a999f3-e90e-4fc4-8c6c-01c6b5d98757    1390    TackMAT -MOUTHING BRADDON WITH PLAYERS  \N      f       \N      75.5    f       75.5
f4b6c8ae-e507-4a4f-bd66-f7f969bcd61e    1342    TackMAT -NUMBERING IRON STICK   \N      f       \N      2.5     f       2.5
a3e124de-18e0-459d-b4a8-8f931ebe4dcf    1394    TackMAT -NYLON HEAD COLLAR-FOAL \N      f       \N      \N      f       36.90627906976744
9d9a4a4d-cccc-4b77-8278-87eb38b62832    1396    TackMAT -NYLON HEAD COLLAR-PONY \N      f       \N      18.9    f       18.9
911627cd-4b25-402a-b2cf-3f05652b9813    1397    TackMAT -NYLON LEAD REIN W/ CHAIN       \N      f       \N      42.5    f       42.5
56405a49-a299-49ea-89eb-62057b992bb9    1399    TackMAT -NYLON LUNGING CAVESSION        \N      f       \N      94.11555556     f       94.115
fa6719ac-d788-4ad4-9189-001df2a7ec6e    1400    TackMAT -NYLON ROPE 10 MM       \N      f       \N      47.5    f       47.5
3e3e6905-32bb-4680-9325-3e94affc41be    1401    TackMAT -NYLON ROPE 12 MM       \N      f       \N      65.5    f       65.5
964924c3-87ac-4f2e-8d51-db039e224f80    1402    TackMAT -NYLON ROPE 18 MM       \N      f       \N      72.5    f       72.5
82d57c23-1b07-4c8d-808f-af7d98f57b85    1403    TackMAT -OVER REACH BOOT        \N      f       \N      55.5    f       55.5
f93858d7-c91d-42ef-a05a-02903471f90a    1404    TackMAT -OVERLAY GIRTH  \N      f       \N      65      f       65
dd6b96c2-6ef1-4adb-ac04-db4ee0f201e3    1405    TackMAT -PEACOCK SAFTY STIRRUP-PAIR     \N      f       \N      90.5    f       90.5
3850575e-eae3-4896-b9be-b1cda5f3a3a7    1406    TackMAT -PEARS SHAPE HOOF PICK  \N      f       \N      \N      f       0
356d740f-e31e-4e09-b2e7-50cd07c15225    1407    TackMAT -PICK SOFT BELL BOOT    \N      f       \N      120.75  f       120.75
f5e36dc5-eead-4e42-88dc-c75f3d235137    1408    TackMAT -PIKEUR BREECHES        \N      f       \N      88.5    f       88.5
f1fccdcf-28dd-4a8e-af09-d01239932422    1409    TackMAT -PIKEUR LADIES BREECHES \N      f       \N      90.5    f       90.5
b6f7b8b8-dff8-488b-9f43-997072db62af    1332    TackMAT -PLASTIC FLY FRINGE     \N      f       \N      18.5    f       18.5
41482286-0137-4c13-bc00-f6cea222ccd5    1410    TackMAT -PLASTIC MUZZLE \N      f       \N      85.5    f       85.5
7568ab12-9dfb-4537-90cd-cb3e408eb7e5    1538    TackMAT -PLASTIC STABLE BASIN (OLD)     \N      f       \N      35.5    f       35.5
7149bac8-f8e3-4d3b-9628-4d3e3a4019a2    1411    TackMAT -POLO BANDAGES  \N      f       \N      58.99636364     f       58.99636363636363
222179c5-136d-4d40-8ce4-416088839d59    2051    TackMAT -PONY BRIDLE SET        \N      f       \N      \N      f       20
ded15386-1c05-419e-a4d9-97f55b70e85b    1412    TackMAT -PONY WARMA BLANKETS    \N      f       \N      95.5    f       95.5
a8d17af6-562b-4ac9-b53f-90bb53902ab7    1413    TackMAT -PROFESIONAL SKULL CAP  \N      f       \N      105.5   f       105.5
75858ca2-8a15-4720-aee1-44c540cb16fa    2378    TackMAT -Pinchless SS Pelham Bit Jointed Mouth  \N      f       \N      \N      f       160
0ceb4bb2-3d89-4be8-9db8-6396128d30c4    2371    TackMAT -Plastic Sweat Scrapper \N      f       \N      \N      f       12
b56a9198-1405-4e31-aa76-2e13c217a9e0    2374    TackMAT -Polo Wrap Set 4x20     \N      f       \N      \N      f       120
2ccf2bc2-5b94-4e0a-9378-e4ba75e6cf29    1505    TackMAT -QUARTER MARKER \N      f       \N      30      f       30
8789143e-d18e-485f-b77f-7cfef48e7e8a    1414    TackMAT -QUICK CHANGE MARTINGLE \N      f       \N      48.5    f       48.5
f5f79d9f-acdf-480f-9dc3-e3c2b24e7042    414     ClinicMAT -Dextrose 50% 500ml   \N      f       1       \N      f       15.752272727272727
d4054e93-f03d-4bb6-92bf-d6b1d937f889    396     ClinicMAT -Diazepam (50ml bottle)       \N      f       50      290     f       550
95fd8cf1-7fe5-452a-9c84-abc5ea7f6e0d    288     ClinicMAT -Digital Thermometer  17.2    f       1       17.20055556     f       17.20017857142857
2104ccba-28ea-480b-a06b-34a09dd37fc8    360     ClinicMAT -Disposable White Coats       2.68    f       1       2.6795  f       2.679565217391304
873e4c7c-ca52-4e45-8369-003e33284a5a    290     ClinicMAT -Duphalite 500ml      40.28   f       1       47.22318182     f       75
7617ac57-548f-4811-8502-acb7accd8d77    366     ClinicMAT -Ekyflex Tendon       619.5   f       1       619.5   f       619.5
5fcd037b-8ee8-4a9f-bc21-d4050a19fc58    365     ClinicMAT -Ekyflogyl (125ml bottle)     \N      f       1       \N      f       197.4
a4e0dbb4-a350-4336-b890-dabd2f35d306    224     ClinicMAT -Elastoplast Bandage  29      f       1       \N      f       29
f6331a26-5e94-480e-aa0f-12882b288879    424     ClinicMAT -Elevate 8oz  346.5   f       1       \N      f       346.5
67bd15c4-8a78-47ee-84ac-4caffc4e0dbb    2101    ClinicMAT -Enalees Streptococcus Equi   \N      f       5       592.862 f       594.142
141efa31-5794-43d4-bfc3-d8b8b64ff9ee    310     ClinicMAT -Epsom Salts 500g     9.92    f       500     \N      f       9.92
ddf74121-0cd5-47a6-a0b7-c9f980774ca8    291     ClinicMAT -Equest Oral Gel      55.1    f       1       55.10333333     f       55
49fc0f86-5f3e-4d17-a9ae-674f2fa2f218    340     ClinicMAT -Equilis Prequenza Te 200     f       1       55.01333333     f       55
23a202ca-720a-420e-beb7-0ba7fedd9f58    372     ClinicMAT -Equine Profile Plus (12pce/box)      1353.6  f       1       \N      f       1304
10b1ab7e-ea28-4bc1-81f4-a158e13c8098    390     ClinicMAT -Equitop Myoplast 1.5kg       409.5   f       1       409.5   f       409.5
0645e2db-07a5-4248-9c30-fc97f3626758    410     ClinicMAT -Equivet Stomach Pump 452.55  f       1       452.55  f       452.55
d4c73df4-2423-4283-92e0-bb48ac93b5e2    406     ClinicMAT -Equivet Stomach Tube M (16x2700mm)   339.15  f       1       339.15  f       339.15
7e21817a-5e46-4545-ad6e-c64f6b95da6c    408     ClinicMAT -Equivet Stomach Tube S (13x2700mm)   312.9   f       1       312.9   f       312.9
a924ac86-0220-42be-8253-a678bbc40c6b    409     ClinicMAT -Equivet Stomach Tube S (9x2100mm)    \N      f       1       \N      f       288.75
9bc78d68-277b-46d4-9516-aa01e39336b2    2201    RidingSchoolSRV-BHS Stage 1     1000    f       \N      0       t       0
27081a79-aae4-4be5-9e6f-c3ab91e1385a    2291    RidingSchoolSRV-BHS Stage 1 Course Semi-Private 1700    f       \N      0       t       0
9e1217aa-1721-48cd-b401-dbc398dd8316    2200    RidingSchoolSRV-BHS Stage 2     1500    f       \N      0       t       0
62641746-08ab-45c3-b80f-f12c082f7f4f    1821    RidingSchoolSRV-Group Lessons - 16  Lesson Package (SH) 3040    f       \N      0       t       0
17b3f81e-cc8d-4b24-9b18-b3c8954666b8    2203    RidingSchoolSRV-Group Lessons - 16 Lesson Package (SH)-t        3040    f       \N      0       t       0
f9de6a89-1096-489b-a097-b9fb712eaa87    2109    RidingSchoolSRV-Horse  leasing  \N      f       \N      0       t       0
858467f3-0ae1-4bea-815c-543c95502145    2043    RidingSchoolSRV-Instructor Schooling - 10 Session Package       1800    f       \N      0       t       0
5b30041c-105c-4acd-950b-ed31e6aa99c7    2204    RidingSchoolSRV-Instructor Schooling - 10 Session Package-t     2700    f       \N      0       t       0
98f8913b-b495-4081-bd40-a1ba54bc44ad    2044    RidingSchoolSRV-Instructor Schooling - 16 Session Package       2800    f       \N      0       t       0
4a07b945-27a9-4c50-8385-4c83ddf12b1f    2042    RidingSchoolSRV-Instructor Schooling - Schooling One Session    300     f       \N      0       t       0
7a2ea339-cd83-4b35-9a29-72d2b664ee5c    1829    RidingSchoolSRV-Private Lessons - 16 Lesson Package (SH) - Head Instructor      6400    f       \N      0       t       0
1ae0a71b-2d3e-41d0-aa7a-5b721f506a04    1828    RidingSchoolSRV-Private Lessons - 16 Lesson Package (SH) - instractor   5600    f       \N      0       t       0
8d8895a0-4c7a-4db7-b79d-e96542545b0a    1837    RidingSchoolSRV-Semi-Private Lessons - 16 Lesson Package (SH) - Head Instructor 4320    f       \N      0       t       0
5d4f7c59-76cc-48b4-aab0-d69a58d0d36a    1836    RidingSchoolSRV-Semi-Private Lessons - 16 Lesson Package (SH) - instractor      3840    f       \N      0       t       0
d490d9f8-47c4-40fa-b03a-a460374d7548    2046    RidingSchoolSRV-Therapeautic Riding Session - Private 10 Session Package        4000    f       \N      0       t       0
f5dba22f-0604-4f93-b0d6-445efd955783    2169    RidingSchoolSRV-Therapeautic Riding Session - Private 16 Session Package        5600    f       \N      0       t       0
69eb1431-c3ed-48be-98c7-d429817b219d    2045    RidingSchoolSRV-Therapeautic Riding Session - Private Session   450     f       \N      0       t       0
ba6011ed-c4bb-41d9-855d-eb67af19831a    1537    TackMAT -RACE ROLLER BREAST GIRTH       \N      f       \N      347.80333333    f       347.80333333333334
c3fba6a4-29a9-44b8-b5af-de20d237eeda    1417    TackMAT -RED MEARS JACKET       \N      f       \N      97.5    f       97.5
85ba15ae-f8c2-4340-9836-99ce748d16bc    1528    TackMAT -RIDING GLOVES (BROWN)  \N      f       \N      32.9    f       32.9
4b2bcc3c-6154-4c71-9fe7-cace27ebad6d    1503    TackMAT -RIDING HELMET  \N      f       \N      111.88  f       111.88
e63ac7c6-d1cb-4d8f-8025-38e385511f24    1419    TackMAT -RING IN MOUTH TOM THUMB BIT    \N      f       \N      105.5   f       105.5
630260e8-0468-488e-8cb4-55d4f5daa36f    1422    TackMAT -RUBBER CURRY COMB      \N      f       \N      \N      f       8
707d9f14-3967-44a7-88d6-79d7902096c3    2217    SMS Service     \N      f       \N      \N      f       \N
4b511b63-2277-4591-93e9-3c24c6f39bbe    1423    TackMAT -RUBBER FOR P.COCK STIRUP-PAIR  \N      f       \N      5.5     f       5.5
3a017fa7-eb00-4195-854a-210b094d7e3f    1504    TackMAT -RUBBER REIN    \N      f       \N      \N      f       60
466e4cc9-0598-4d63-9077-e838b7002e16    2459    TackMAT -Rubber Martingale Stopper      \N      f       \N      \N      f       3.5
61036d5c-a65e-4b29-af86-f156c17f8e92    388     ClinicMAT -Excenel 4g   252     f       1       252     f       252
77b74b2a-ed84-4d97-a649-207a0f702ca7    441     ClinicMAT -F10 Germicidal Wound Spray   34.65   f       1       34.65   f       34.65
bd93ff22-e57b-4afd-8f20-29a5b579afb5    395     ClinicMAT -Face Mask    4.15    f       1       4.15114286      f       4.150909090909091
06fd062d-2a7e-41a6-9be8-31ec85ffe496    431     ClinicMAT -Fieblings Fly Spray 44       119.21  f       1       \N      f       119.206
9aeaf3ac-cf66-470f-b044-8f48ee905c66    2084    ClinicMAT -First Aid Box Large  \N      f       1       \N      f       230
57e69111-b874-4e75-8a19-84ee2939ffe3    295     ClinicMAT -Fluid Bag Extension Set      54.6    f       1       54.6    f       54.6
12314662-c738-485e-b512-021821d79a93    321     ClinicMAT -Fluvac innovator     \N      f       1       \N      f       85
fae87003-aaed-4c24-bcf0-7ec519fed82f    393     ClinicMAT -Formaldehyde 37% 2.5ltr      57.75   f       1       57.75   f       57.75
dd665359-e842-4653-bb26-a188e3ee4690    311     ClinicMAT -Fucicort     24.06   f       1       \N      f       27
db25e6c6-88ec-4341-91dd-1d61e018244b    338     ClinicMAT -Fucidin Ointment 15g 16.16   f       1       15.66333333     f       15.5
f7b30aaa-a6ed-4ebd-b0ac-7b984c658d1e    386     ClinicMAT -Fucithalmic Eye Ointment     15.25   f       1       16.085  f       15.5
3bdf6e39-d8ef-456c-a382-e3214210d636    226     ClinicMAT -Gamgee Long  61.7    f       1       61.69484848     f       61.69558139534884
0bed4e42-2387-44c1-9468-f41c285bf26f    328     ClinicMAT -Gastro-Aid Paste (60g syringe)       \N      f       1       50.42694444     f       50
6a8f3f16-af0a-4fb3-b467-6721dd9c8b91    227     ClinicMAT -Gastroguard Oral Paste (7pce/box)    \N      f       7       142.85714286    f       110
c74b2f58-bdee-46bb-82b3-e61f03c703cf    387     ClinicMAT -GoldCort 0.5mg/ml (3ml vial) 57.75   f       1       57.75   f       57.75
7f83dc22-4cf6-4df4-92a3-6833981e3a71    346     ClinicMAT -Good As Gold 22.05   f       1       140     f       140
7dbc3638-6414-4488-ad7b-56e056bbc8d8    364     ClinicMAT -Haematology Reagent - HM5    1381.1  f       1       \N      f       1398
3064a79f-6c17-45a8-9065-8fb8b413ed6e    352     ClinicMAT -Hand Sanitizer 5ltr  14.25   f       1       14.25142857     f       14.253333333333334
9c5f64b9-5832-4b29-853d-3c42f3bc331e    312     ClinicMAT -Hydrogen Peroxide (100ml bottle)     5.77    f       1       \N      f       5.767142857142857
7a41ccdc-842a-4dd8-a5b9-f05555a2a5ca    394     ClinicMAT -Hydrogen Peroxide 30% 2.5ltr 68.25   f       1       \N      f       68.25
56348cbf-72ef-446a-bd55-d1aca2e2e97d    322     ClinicMAT -Hyvisc 2ml   \N      f       1       \N      f       275
652b2e3d-6361-4e4f-9d89-e668d90be283    419     ClinicMAT -I Stat Cartridge Chem 8+ (Box of 10) 1004.42 f       1       1004.42357143   f       1004.4233333333333
37c06966-c8b4-4d05-b272-bb82db276938    285     ClinicMAT -IV Catheter 14G 5.25"        31.08   f       1       31.08119355     f       31.08115789473684
e6e0257f-9ab7-4be0-93f2-8cb3444a28a6    1543    TackMAT -SADDLE PAD (BLUE WITH LEATHER) \N      f       \N      150     f       150
172fab95-0fe7-41fe-9122-36dc6f2b69dd    1509    TackMAT -SADDLE PAD BLUE/ BLACK \N      f       \N      176.1975        f       176.1975
79512b19-a86f-4057-886c-cb73aba28137    1519    TackMAT -SADDLE PAD NUMNAH      \N      f       \N      75      f       75
6879ea1a-065c-443e-a11f-e9345e9bb892    1508    TackMAT -SADDLE PAD WHITE       \N      f       \N      75.76916667     f       75.76916666666666
e41e81b7-f61d-46e5-be36-980778c434bc    1428    TackMAT -SADDLE RACK    \N      f       \N      40      f       40
b8d6e9b3-9b61-4e20-84b2-19cac78a9aa8    1429    TackMAT -SADDLE SOAP    \N      f       \N      25      f       50
c2730687-9bcb-4ffe-b7f7-ff68a0d800be    1433    TackMAT -SALT LICK HOLDER       \N      f       \N      25      f       25
050e5724-7a19-4be7-b1d8-34afc3e851c6    1521    TackMAT -SHIRES BOOT PAD        \N      f       \N      45      f       45
a20e6387-2bcf-4ca1-af6d-1160f18a708d    1498    TackMAT -SHIRES ELASTIC BANDAGE \N      f       \N      67.12   f       67.12
59aee610-3cc7-43c8-9718-a4c2c940abe0    1590    TackMAT -SILVER BRIDLE CHAIN    \N      f       \N      130     f       130
b2078253-1f15-4d60-bc71-1357018ced0b    1333    TackMAT -SILVER POLISH  \N      f       \N      19.5    f       19.5
d3f77cc8-b1dd-4bea-9878-13e86d434ccb    1338    TackMAT -SPARE RAKE FOR STABLE MATE     \N      f       \N      22.77777778     f       30
e1027ae5-8546-4650-b876-a3bfdfc38ced    1470    TackMAT -SPLASHERS BOOT \N      f       \N      65      f       65
13209ba8-38b4-46ce-a1c7-df65b256a345    1471    TackMAT -SPUR LEATHER   \N      f       \N      5       f       5
e7f4fea0-8d9d-4ff2-9cfa-ca9565264eeb    1472    TackMAT -SPUR NYLON     \N      f       \N      8.5     f       8.5
10898480-1fa5-4ac4-bd35-bf0247fb0e89    1536    TackMAT -SPURS LEATHER STRAP    \N      f       \N      21.85   f       21.85
c3201622-35e2-4c00-83bc-d69a83d4acee    1473    TackMAT -SSG GLOVES     \N      f       \N      88.34   f       88.34
ab82b833-43d2-4433-9684-b9527e1acadb    1535    TackMAT -SSS SPURS      \N      f       \N      45.5    f       45.5
25d6f726-e72b-47fb-9584-57bcb15c558c    1474    TackMAT -STABLE BUCKET  \N      f       \N      55      f       55
164c9c87-120f-4b02-a442-909f7ae359ba    1541    TackMAT -STABLE FORK    \N      f       \N      \N      f       58.8
2c8de637-48a1-4e6e-a1df-1083b5c18a9b    1475    TackMAT -STABLE MATE    \N      f       \N      55.58947368     f       55
41fc4654-89ef-4bf7-899b-fd09709fdd4f    1526    TackMAT -STABLE PLASTIC BASIN   \N      f       \N      45      f       45
1a42e150-a477-41ea-b0db-08c82ce74077    1525    TackMAT -STABLE PLASTIC BUCKET W/HANDLE \N      f       \N      \N      f       37.33733333333333
6921f875-5bdd-4c1e-b45d-1091bf02e39d    1476    TackMAT -STANDING MARTINGLE     \N      f       \N      85      f       85
e5715096-213c-49ad-abaa-2b5823b2a32f    1478    TackMAT -STAR ELASTIC GIRTH     \N      f       \N      65      f       65
5aca2c37-e583-4c0c-a08a-5dc6173d73bd    1533    TackMAT -STC TOM THUMB RING     \N      f       \N      130     f       130
fe47743e-f1d4-4186-aad0-346c259a3726    1561    TackMAT -STIRRUP STRAPS \N      f       \N      \N      f       26.25
fbcda545-ea37-4488-af02-9aaf651e05af    1544    TackMAT -STIRRUPS (KNIFE EDGE)  \N      f       \N      \N      f       30
468b19a2-489d-4799-8895-eb9a24461f1f    1483    TackMAT -SUMMER RUG SHEET       \N      f       \N      135.16645161    f       135.16645161290322
ffd09d40-996d-4f73-9bbc-80379e7b4195    1484    TackMAT -SUPER DANDY BOY        \N      f       \N      55      f       55
00bcc065-19b0-4c3b-bb96-07c82c8e348d    1559    TackMAT -SUPER IODINE SHAMPOO- 1GLN     \N      f       \N      \N      f       84
68ef71ed-abe8-4636-be51-b168a298703e    1485    TackMAT -SUPER MASK FLY MASK    \N      f       \N      \N      f       60
1a54c59a-34b4-44f9-842d-57507935909e    2380    TackMAT -Stud Box       \N      f       \N      \N      f       130
59e5751a-b4cb-43ae-a149-4a353be9a2c0    1487    TackMAT -TRIMMING SCISSCORS     \N      f       \N      13.5    f       13.5
94639d11-10a5-41e5-8d97-f31a2bda5f8c    1341    TackMAT -TUBE SIZE 4.80/4.00-8 (WHEEL BARROW)   \N      f       \N      21      f       21
40f8d516-fe86-43af-839a-247bcbca768e    1339    TackMAT -TYRE 400-8 & TUBE      \N      f       \N      140     f       140
1dca0387-1406-4ca2-9fb2-33044cbacde4    2183    TackMAT -TYRE For Wheel Barrow  \N      f       \N      256.73913043    f       260
2a8cab92-9bcd-45f3-9eb5-ec0ee028d2c6    2375    TackMAT -Tail Wrap Size 12.5"   \N      f       \N      \N      f       125
7bf6e870-beda-4b51-86aa-e2d01d9a427d    2373    TackMAT -Training Bandage Set Of 4      \N      f       \N      \N      f       64
48bb6fff-75cc-4520-9338-c2689a98f9ab    1340    TackMAT -UAE ENDURA HELMET      \N      f       \N      175     f       175
54ee4b35-46f8-486d-a92b-e06aaf99e462    2221    TackMAT -ULTRASHIELD FLY SPRAY 1GAL     \N      f       \N      390     f       390
d2828861-7ccf-4b58-a69c-ee6659681b2b    2220    TackMAT -ULTRASHIELD FLY SPRAY 1L       \N      f       \N      125     f       125
bba107c7-12b7-4eec-916a-70d63cb1f285    1488    TackMAT -UMBRIA BOOT    \N      f       \N      105     f       105
b4999a46-051f-428e-ae2f-6b32b995bb71    1563    TackMAT -WATER BUCKET BIG       \N      f       \N      \N      f       220
c55a5c9c-79c2-434d-9c21-ca37d5811492    1510    TackMAT -WEBBER EXTENSION       \N      f       \N      19.5    f       19.5
7ce981a4-3b2f-4175-807b-37942b930cb1    1331    TackMAT -WHEEL BARROW 500L      \N      f       \N      \N      f       3550
d563effe-50c8-4cb9-982c-a44167ffb0be    2565    The Garden Season Pass Adult    800     f       \N      \N      f       0
d0765e98-ddc1-4e99-bb1e-70e320accd2e    2556    The Garden Season Pass Child    666.6666667     f       \N      \N      f       0
70d2e040-1d8b-4496-8e88-b46b524ee5fb    2718    The Pavillion Suite 1 Day Pass - Table of 8 People      9523.8095       f       \N      \N      f       0
faa4f297-4a57-4f29-af81-22a17bbc45f7    2706    The Pavillion Suite 3 Days Pass - Table of 8 People     23809.5238      f       \N      \N      f       0
3b696366-19d0-43fe-8b0d-831e88d7d0b5    2707    The Prestige Lounge 1 Day Pass - Table of 6 People      11428.571428    f       \N      \N      f       0
2ac44d75-769c-49fa-b1fc-2e26099ee9d8    2717    The Prestige Lounge 2 Days Pass - Table of 6 People     19047.619       f       \N      \N      f       0
8ecfa184-cafb-4008-ad4d-c987712ac746    2708    The Prestige Lounge 3 Days Pass - Table of 6 People     28571.42857     f       \N      \N      f       0
ec1d43d9-3633-425f-b964-85262cf9a0e9    2709    The Prestige Lounge 3 Days Pass - Table of 6 People (20% Discount)      22857.142857    f       \N      \N      f       0
aa1a69db-7fc9-43fb-9f6d-4fce22ea54df    2865    Third Party Service – Ataya Event 2026 May      \N      f       \N      \N      f       0
e4448e30-18bb-4e5b-9051-39810cecef59    2768    Third Party Service – Cobbler Village, Hoarding & Vinyl Application     \N      f       \N      \N      f       0
e217b09f-5873-45f6-ba29-a61319031bd3    2769    Third Party Service – Jonas Burger Extension Works      \N      f       \N      \N      f       0
1a0e22b1-94b1-41cc-b538-6bda7e6f4137    2835    Third Party Service – Marjorie Harvey   \N      f       \N      \N      f       0
1d2950fb-b21d-4e4e-b900-f4a2eca5edb2    2833    Third Party Services Additional work SOLENN PO-26-00309 – VEN-01391 ARC Building Contracting L.L.C      \N      f       \N      \N      f       0
40dab2f1-5269-4f5d-bd54-6e4c943cd6cf    2764    Third Party Services Arabian Show February 21st - 23rd 2026     \N      f       \N      \N      f       0
7479af0a-12c7-4fa0-ba03-c5f9873ba253    2712    Third Party Services GCAT Jan26 \N      f       \N      \N      f       0
fcedb291-76af-4239-921c-80b12df4066f    2837    Third Party Services – Additional Work (La Romana) – PO-26-00281 – VEN-01391 ARC Building Contracting L.L.C     \N      f       \N      \N      f       0
b8562cbe-7572-43c6-bc9b-94b345e94844    2866    Third party Service - KLEI SPA  \N      f       \N      \N      f       0
fb5b024a-a359-4040-bdd5-90593e3e95f7    2622    TobaccoMAT -A.FUENTE CHÂTEAU FUENTE CUBAN BELICOSO SG   \N      f       \N      173.29416667    f       173.29375
184b9dcb-75fd-478d-9c37-a4bf51ccef52    2612    TobaccoMAT -BOLIVAR BELICOSOS FINOS SLB \N      f       \N      160     f       160
3171564e-64da-4681-9fb0-64a623ab6b4b    2613    TobaccoMAT -COHIBA ROBUSTOS     \N      f       \N      426.972 f       426.972
db3b1cad-acb3-4c31-948b-e0f1ec0be5e2    2627    TobaccoMAT -Confidenciaal Fiftyfour     \N      f       \N      85.71434783     f       85.7144
3f104b2c-5e71-4f36-83a6-5f2516329700    2628    TobaccoMAT -Confidenciaal Lancero       \N      f       \N      \N      f       95.238
409da5e5-9927-43a1-b1fc-06096f9b4d1a    2614    TobaccoMAT -HOYO DE MONT LE HOYO DE SAN JUAN    \N      f       \N      194.54411765    f       194.544
5572c21a-2724-49e8-8e6a-fd10973a87a4    2304    Saddle Cloth    \N      f       \N      \N      f       \N
692c0905-72dc-420c-93d1-a673227356e0    2615    TobaccoMAT -MONTECRISTO MEDIA CORONAS   \N      f       \N      78.96   f       78.96
3ba07498-9afd-480f-b524-fe76dca664f2    2626    TobaccoMAT -My Father Cigar Tatuaje RC Series No.1      \N      f       \N      152.381 f       152.381
7780b63d-6066-47df-8b4d-97fad9b0a16a    2625    TobaccoMAT -My Father Cigar Tatuaje RC Series No.2      \N      f       \N      161.905 f       161.905
d022c72f-08bb-47bd-a328-74459f929c32    2624    TobaccoMAT -Oliva Serie V 135 Aniversario Perfecto      \N      f       \N      166.66652174    f       166.66666666666666
8e0845f1-8f99-40bc-9736-3586c50aa9d4    2623    TobaccoMAT -Oliva Serie V Torpedo       \N      f       \N      128.57145833    f       128.57145833333334
52b30b17-cd22-4e97-809b-04f7dda4745d    2619    TobaccoMAT -PARTAGAS SERIE E #2 \N      f       \N      193.91428571    f       193.914
4424d9f1-c01f-4eda-97fa-443ae9d51a78    2629    TobaccoMAT -Plasencia Alma Fuerte Eduardo I     \N      f       \N      219.0475        f       219.0475
b0f194bb-d931-4ac7-a5cc-445e9228df1d    2620    TobaccoMAT -ROMEO Y JULIETA SHORT CHURCHILLS 25 \N      f       \N      160.482 f       160.482
70bf6a9d-745b-4890-ab97-f7e4345dcdf3    2621    TobaccoMAT -TRINIDAD MEDIA LUNA 12      \N      f       \N      242.725 f       242.725
88332bd6-78f6-4eae-882f-cca181363a52    2299    UniformnMAT - Arm Sleeves 2025  \N      f       \N      15      f       15
bc927b51-eafd-4ced-a720-a7c5b338008b    2298    UniformnMAT - PANT & T- SHIRT  2025     \N      f       \N      \N      f       110
6179dc68-9431-4b87-957e-8d1a8ebc9615    696     UniformnMAT - PANTS & T- SHIRT FOR ADEC WITH LOGO       \N      f       \N      84.18862745     f       84.18862745098039
44e3f969-f99e-4d29-8944-7f6babe819a0    2302    UniformnMAT - Winter Jacket  2025       \N      f       \N      \N      f       125
630b341d-5d37-402f-b0f5-10dc598d4f24    708     UniformnMAT -ADEC LONG SLEEVE WINTER JACKET WITH EMBOIDERY      \N      f       \N      53.13   f       53.13
d122d84b-969d-470a-b340-78edc36c8582    695     UniformnMAT -ADEC OVER ALL      \N      f       \N      38.29466165     f       38.29466165413534
47ae9005-5100-43f9-885c-c19d9d40a125    701     UniformnMAT -ADEC OVERALL OLD UNF       \N      f       \N      35      f       35
257e3fcb-6244-4832-8186-098ce5668f0f    706     UniformnMAT -ADEC POLO T- SHIRT WITH EMBROIDERY \N      f       \N      107.51  f       110
387eeff4-26d9-434e-92b0-99be0a70561e    697     UniformnMAT -ADEC RED SHIRT     \N      f       \N      25.5    f       25.5
1c21013b-c864-4835-b8e4-7c675976db2d    707     UniformnMAT -ADEC TROUSER WITH EMBIODERY        \N      f       \N      65.1    f       65.1
4776c2b8-36ca-470f-ab01-5f4170983a9d    2792    UniformnMAT -Customized cargo pants-GROOM FARRIER       \N      f       \N      48      f       48
92679f22-6bab-4000-8a12-27473700b632    2794    UniformnMAT -Customized cargo pants-GROUND CREW \N      f       \N      \N      f       70.835
59d2fb47-c897-4edc-ac1a-7adab551f761    2797    UniformnMAT -Customized cargo pants-SECURITY    \N      f       \N      \N      f       70.825
09af75cb-8195-4adf-b25d-006f6a94932c    2193    UniformnMAT -Executive Pants    \N      f       \N      \N      f       125
582b4f29-9e80-4907-9e49-993c90709b6c    2192    UniformnMAT -Executive Shirt    \N      f       \N      \N      f       95
f1eeac18-5ca7-4c7d-af44-70bd31008012    703     UniformnMAT -FORMAL BELTS       \N      f       \N      \N      f       35
864742c9-4963-4a1a-a3a7-e2c3ac02ebf5    702     UniformnMAT -FORMAL SHOES       \N      f       \N      \N      f       145
a877fa01-f7b7-4faf-9cc3-395420e6499a    2194    UniformnMAT -Formal Vest        \N      f       \N      \N      f       39
131f1b97-c0cb-461d-9ea6-bf10a3fa7fdd    709     UniformnMAT -GREEN JACKET       \N      f       \N      175     f       175
2ade9727-11a0-4230-8e0c-911cd6de960a    693     UniformnMAT -JACKET BLUE/BLACK  \N      f       \N      75      f       75
4b4f0715-040d-4405-b72a-21b003fa31f4    2135    UniformnMAT -Media Vest \N      f       \N      \N      f       39
2a79ea99-70c6-497a-b94d-779a9c42c3bc    2195    UniformnMAT -Name Badge \N      f       \N      \N      f       35
24941162-bacd-4793-845e-d65d6979cf23    2196    UniformnMAT -Neck Scraf \N      f       \N      \N      f       45
648ed6d6-8d22-40c9-bbe8-b02453207034    2287    UniformnMAT -Nylon SAFETY GLOVES        \N      f       \N      9.16157895      f       9
81c6ff44-61ab-4ccc-8c68-e033ac0b99f3    698     UniformnMAT -OVERALL (OLD)      \N      f       \N      40.5    f       40.5
a9eb9fdf-fa16-4162-b99f-ae01e6e99aa7    700     UniformnMAT -OVERALL BIEGE      \N      f       \N      40.5    f       40.5
d2ed4d56-9818-4b40-aec5-dd2df1fd054f    2796    UniformnMAT -Polo T-shirt with logo, WHITE-SECURITY     \N      f       \N      \N      f       70.835
324cfe31-d9ae-4f19-bd04-c007ea076979    2790    UniformnMAT -Polo T-shirt with logo-GROOM       \N      f       \N      32      f       32
d69e09cf-64b4-4019-ba59-e9dce2b72a54    2793    UniformnMAT -Polo T-shirt with logo-GROUND CREW \N      f       \N      38      f       38
598e771d-bfbe-4fc6-9628-60a4e2d9187f    699     UniformnMAT -RED PANTS  \N      f       \N      25.5    f       25.5
7017e12e-701f-48aa-aab4-6a395997275c    2288    UniformnMAT -Rain Coat  \N      f       \N      \N      f       25
ce0e02a4-0305-4a47-8708-9ea19442e49a    2187    UniformnMAT -SAFETY SHOES – BRAND BSW   \N      f       \N      95.02333333     f       95
11e6c7ee-c501-4bfc-9584-9b2995b9d935    704     UniformnMAT -SAFETY SHOES – BRAND MTS   \N      f       \N      126     f       126
9b11377d-7975-4007-bad2-1925a6fc9d95    705     UniformnMAT -SAFETY SHOES – BRAND TALAN \N      f       \N      142.8   f       142.8
8d4a7af3-2135-4bce-98d1-8a99a95367f4    2317    UniformnMAT -T- SHIRT 2025      \N      f       \N      \N      f       50
993a4397-8278-4c58-a283-95099cd73a4c    694     UniformnMAT -T-SHIRT FOR AL WATHBA      \N      f       \N      61.66125        f       61.66128205128205
1652916f-7437-48ff-bd13-2177c97516ae    2412    Utilities consumption   4000    f       \N      \N      f       0
27cc24de-72b2-4de5-a1f4-c9b921816eae    2389    VenuLeasingSRV- Arena Leasing   \N      f       \N      \N      f       0
c72247aa-885a-4163-99c7-c07ef58e1b00    2699    VenuLeasingSRV- Booth 4x4       3000    f       \N      \N      f       0
bf8ffd6b-8ee7-4e77-bae3-b90b0380e27d    2756    VenuLeasingSRV- Booth 4x4 (Without Shelves)     2500    f       \N      \N      f       0
57dbe830-2c89-4ab9-b35e-c615adf01908    2700    VenuLeasingSRV- Booth 4x8       5000    f       \N      \N      f       0
af6d36c7-fa5c-4248-a81a-3d68c3a64674    2572    VenuLeasingSRV- SAND Track Hourly slot Leasing  \N      f       \N      \N      f       0
9c09cd5a-f461-498b-afe9-3cebc04d0ba0    2053    VenuLeasingSRV- SAND Track Monthly slot Leasing \N      f       \N      \N      f       0
99d7b175-d8b7-46c8-a909-ae9adb871cca    2198    VenuLeasingSRV-premises Leasing \N      f       \N      \N      f       0
3da669cb-3652-4f19-ae53-d405024429c8    2064    WoodShavingMAT -Equidos Wood Shaving 20 \N      f       \N      \N      f       2.2
2e7776f4-2364-4816-a44b-41f6555d72e8    2871    WoodShavingMAT -GOLDSPAN DUST FREE WOOD SHAVING 20KG/BAG        \N      f       \N      \N      f       \N
f9dad2a4-d57c-41fd-bf9c-23fbc9b47380    2416    WoodShavingMAT -LOCAL WOOD SHAVING 14KG \N      f       \N      29.5    f       29.5
f51f3505-c5d7-48ad-8d6e-50c966e1ed52    436     ClinicMAT -IV Catheter 16G 1.8" (45mm) (50pce/box)      131.25  f       1       131.25  f       131.25
3ae9e0c4-c285-4e66-a1c3-5506d89c9016    342     ClinicMAT -IV Extension Set     4.56    f       1       4.55697674      f       4.557
bba73626-ec22-4c25-9dd2-1ff239c45615    263     ClinicMAT -IV Giving Set (Wide Bore)    34.53   f       1       34.53025        f       34.5302
711da787-5bf4-4afc-9413-e2a2a0029273    314     ClinicMAT -Intraepicaine (10ml bottle)  \N      f       1       88.49498772     f       88.47058823529412
cb596d47-45b1-44f7-a3e0-87bf8d19329e    231     ClinicMAT -KY Jelly     13.97   f       1       13.9675 f       13.968333333333334
3b4d9202-f20a-4dba-9ec5-62b2c0a930ee    261     ClinicMAT -Kaopectate (480ml bottle)    56.44   f       1       \N      f       56.44
7a066fd3-a542-4ae5-87a3-75b214579864    323     ClinicMAT -Keratex Hoof Hardener        153.33  f       1       \N      f       325
ed7a74ae-0ed1-4385-92a8-abe83ad2772a    345     ClinicMAT -Keratex Mud Shield Powder    55.23   f       1       55.22666667     f       55.22666666666667
bb947d43-f11e-445b-a320-9e37d16938fb    264     ClinicMAT -Krusse IV Bag Swivel Hanger  1155    f       1       1155    f       1155
905100fc-2ab2-491a-b21c-da86fb784a0d    369     ClinicMAT -L-Carnithine 173.83  f       1       173.83333333    f       173.83333333333334
519cfd48-3450-4fcd-a33d-f636f1bcc638    265     ClinicMAT -Large Bore IV Giving Set     94.66   f       1       94.66   f       94.66
756346ca-9a03-4ace-a45b-8e1131931d82    331     ClinicMAT -Lincoln Witch Hazel & Arnica Gel 400g        44.1    f       1       44.1    f       44.1
a585221a-cd90-4d97-8f40-35831395eaca    339     ClinicMAT -Liquid Parafin 5ltr  59.3    f       1       59.30428571     f       59.303636363636365
7de3ded2-98ca-4e41-afaf-347410e44f18    2032    ClinicMAT -Malaseb Shampoo      125     f       1       74      f       74
899489d6-3a74-4ddb-8f63-5282284c15c3    443     ClinicMAT -Manual Reusable Ambu Bag Large (Adult size)  288.75  f       1       288.75  f       288.75
7145ed7f-cffd-4814-b680-646d55fb238e    378     ClinicMAT -Millex GP Filters    \N      f       1       \N      f       903
bcca42e9-926f-4f36-a6d8-ed16834bc851    303     ClinicMAT -Needles 16G 1.5"     18.95   f       1       18.955  f       18.954
f586f3f5-75d9-4727-9041-ed040bc12565    315     ClinicMAT -Needles 18G 1.5" (Pink)      10.87   f       1       10.875  f       10.873333333333333
640ec061-9d3d-428c-95ba-4bb55ae84e3e    337     ClinicMAT -Needles 19G 1.5"     10.5    f       1       10.5    f       10.5
aaf9479f-748c-4c04-8279-432841fe58af    236     ClinicMAT -Needles 20G 1.5" (Yellow)    \N      f       1       10.5    f       13
4b9fcee3-7268-4b06-a91b-45ae11fc503a    234     ClinicMAT -Needles 21G 1.5" (Green)     \N      f       1       10.5    f       10.5
5a4059ee-7b76-4510-89e9-8bb212a47456    235     ClinicMAT -Needles 23G 1.5" (Blue)      12.47   f       1       12.47   f       12.468
ac7e27f4-bc37-4941-a01f-2c6a78d488b6    316     ClinicMAT -Needles 25G (Mesotherapy)    23.59   f       1       23.59   f       23.59
485337ed-d337-4fee-b6f7-d467a46173a7    359     ClinicMAT -Needles 27G (Mesotherapy)    \N      f       1       29.425  f       40
336f0a74-1f14-4db1-96c4-64d02bc4ac54    307     ClinicMAT -Nitrofurazone Cream  84      f       1       84      f       84
76a705b5-bcb8-4805-8172-667771a1cbf5    301     ClinicMAT -Non-Sterile Gauze 10x10cm (pack)     \N      f       1       6.89529412      f       7
1d448d13-04b0-4ba5-bd14-1dedcd57586c    270     ClinicMAT -Normal Saline 0.9% - 1ltr    9.6     f       1       8.71133333      f       8
d14b1031-a559-4013-bdc0-cb755368ca66    2035    ClinicMAT -Orondo Antibiotic Spray      19.84   f       1       19.83333333     f       19.835833333333333
b7065cb9-65fa-427b-adc6-52315b4c3a76    377     ClinicMAT -Osphos (15ml bottle) 971.25  f       1       971.25  f       971.25
6925ceb6-8f53-4e2b-b1f1-76924af14ef9    2863    ClinicMAT -Ovu-Mate Oral Solution 1Ltr  1030.32 f       1       \N      f       750
983452ae-ff31-4f45-a50a-f8f3b5118804    350     ClinicMAT -Phenylbutazone Paste 31.5    f       1       \N      f       31.5
af510b5e-8aae-46ff-8586-e48a9481d755    420     ClinicMAT -Pipette 10-100UL     \N      f       1       42.44   f       42.44
e2a6c6bc-b5e5-47b5-bc71-1a2ea326bca8    402     ClinicMAT -Protexin Gut Bind Paste 30ml 89.25   f       1       \N      f       85
d5323a42-f429-4657-ada4-e6963e8653ac    398     ClinicMAT -Rabisin Vaccine      12.11   f       1       12.10769231     f       12.107692307692307
0d71ff4e-0807-4417-8955-d1a996aaf791    329     ClinicMAT -Radiol 500ml 87.15   f       1       87.15   f       87.15
093b508a-d718-4908-a036-c83ad1faf805    2212    ClinicMAT -Randlab TMPS Paste 500g      357.75  f       1       265     f       265
7e7aa885-7b68-4043-b5c7-eb8d4f25fadf    267     ClinicMAT -Rectal Gloves        74.89   f       1       74.88857143     f       74.88875
deea66bf-53d5-4282-b288-e823c57c26f1    426     ClinicMAT -Sand X Psyllium 10kg 450     f       1       450     f       450
9b587df8-bf6e-4ffc-9253-b515f5138027    418     ClinicMAT -Scalpel Blade (Size 21)      84      f       1       84      f       84
35e406ab-7197-4ad0-89cf-582d770927cd    353     ClinicMAT -Scalpel blade (Size 23)      84      f       1       84      f       84
86f448b0-acc6-470c-a52e-b0cc3f212ada    324     ClinicMAT -Septicare Gel 1ltr   64.45   f       1       64.445  f       64.445
bd83fd43-6459-4973-93d6-2542da037623    371     ClinicMAT -Sharps Bin   17      f       1       \N      f       17
36ff5786-5b0d-411b-9ee4-0061a04be98a    343     ClinicMAT -Skin Stapler (pce)   50.61   f       1       50.61333333     f       50.613125
cc0211fd-d895-44f5-bee6-c51df726b8d5    375     ClinicMAT -Smartpak Equine One AC 200g  175.21  f       1       175.21  f       175.21
9cdd868c-8a04-4060-8ee6-e1ded030ae52    401     ClinicMAT -Solumedrol 1000mg    266.64  f       1       266.64454545    f       266.6446875
dc94966b-34ae-48ef-aa99-9a0a7fc13a52    304     ClinicMAT -Spinal Needle 20G 3.5" (405253)      204.75  f       1       204.75  f       204.75
58db759b-f51d-4f12-9a8c-320c1148d1bb    382     ClinicMAT -Splintex Gold        141.75  f       1       141.75  f       141.75
c51bfd46-db65-47d5-a74f-128639ed335c    383     ClinicMAT -Splintex Silver      126     f       1       126     f       126
93f051d9-de4e-44cc-8905-67b28108fc35    397     ClinicMAT -Stallion Urinary Catheter 7.3x1350mm 5/packet        320.95  f       5       320.95  f       320.95
727fde4c-5579-46e0-b3e9-dd859443e7cb    2168    ClinicMAT -Sterile Gloves Size 7 (50pce/pack)   60      f       1       48      f       48
a43242d5-0a61-46b5-9d5f-05ec7b3cab1c    292     ClinicMAT -Sterile Gloves Size 8 (50pce/pack)   \N      f       1       77.85634744     f       78
dc09f774-56a1-4642-9702-aae850fb4147    438     ClinicMAT -Sterilisation Pouch 12x15 (200/box)  \N      f       1       \N      f       164
e9a8e782-2f75-43ed-8fe4-11792e9ce104    437     ClinicMAT -Sterilisation Pouch 12x18 (200/box)  141.75  f       1       \N      f       141.75
2d3ed4fe-85c4-4676-9b2d-bf532dd5ad82    439     ClinicMAT -Sterilisation Pouch 9x15 (200/box)   \N      f       1       \N      f       106.25
f19b7258-90fd-4336-b1d6-6aed779833aa    425     ClinicMAT -Sucralfate 1g Tablets (500tabs/box)  \N      f       1       \N      f       195.99489795918367
f9008598-cf38-4860-940f-b4df798dbe63    415     ClinicMAT -Supramid Size 0      236.25  f       1       \N      f       236.25
b9fecdc4-a11a-4e74-a9fd-7cdef86de385    348     ClinicMAT -Syringe 50mls        62.19   f       1       62.19   f       62.1875
f5de1dd3-cd73-4ab9-beb0-29e1d149f2a5    368     ClinicMAT -Syringe Catheter Tip 49.34   f       1       49.34333333     f       49.342
98e1d379-6cd6-4eda-afad-e702a90f50ae    244     ClinicMAT -Syringes 10ml        \N      f       1       43.47666667     f       25
157dd8e6-69c6-4707-b219-f01e2fc493b8    275     ClinicMAT -Syringes 1ml 48      f       1       \N      f       48
a88448ba-910c-43c5-a526-04f46e7428ac    245     ClinicMAT -Syringes 20ml        43.32   f       1       45      f       20
8cf7c045-85e0-4c00-956a-f723e62fd80a    246     ClinicMAT -Syringes 3ml \N      f       1       27.58   f       28
d79bf07e-3697-4cfc-9072-bfcc0f304389    247     ClinicMAT -Syringes 5ml 43.38   f       1       39.538  f       38
a81fc0b4-1735-4d2a-a03f-6724cf4c9ed3    293     ClinicMAT -T-61 (50ml bottle)   259.82  f       1       259.815 f       259.81888888888886
a178e8c9-4323-4db1-98bc-a61e895b59d9    2028    ClinicMAT -TMPS Injection       44      f       1       \N      f       40
11b2e89f-6088-4227-a529-3c3114650e0a    2025    ClinicMAT -TMPS Oral - BOX      160     f       1       \N      f       160
71503f5b-25c9-418a-bf39-2c8df2215d2f    446     ClinicMAT -Tensoplast Bandage 10cm Roll \N      f       1       55      f       55
acb7141c-b072-4d92-86ca-a79af38cfc20    445     ClinicMAT -Tensoplast Bandage 7.5cm Roll        30.45   f       1       \N      f       30.45
b1dd64b5-be75-4912-959c-0aefd73a5fd4    367     ClinicMAT -Tobradex Eye Ointment        18.38   f       1       17.74666667     f       17.5
cb9a449d-05e1-4b9f-9f5f-f98b58ad858f    318     ClinicMAT -Traumeel 5ml Ampoules (50pce/box)    1312.5  f       1       1312.5  f       1312.5
a9e06bee-905c-48ab-aa83-1e8ca32f7f65    249     ClinicMAT -Ultrasound Gel (250ml)       5.5     f       1       5.49506173      f       5.495061728395062
a1ded1b0-049b-42d9-9fa4-3792fd9282f8    423     ClinicMAT -Urinanalysis Strips  85      f       1       85      f       85
0d4f0478-5695-4cb3-9469-9a762a7cf032    294     ClinicMAT -Vam Inj (100ml bottle)       \N      f       1       \N      f       94.5
3c930dab-4561-48ac-9105-2fe34b3d7c92    319     ClinicMAT -Vaseline (450g)      24.84   f       1       \N      f       24.838333333333335
85935971-0388-4bf4-b7d6-b8ca553d25dd    430     ClinicMAT -Ventipulmin Granules 500g    \N      f       1       \N      f       400
232a9fab-ea25-4d65-8699-0c6efbb56320    448     ClinicMAT -Vetscan Hemaclean Solution   52.5    f       1       51.25   f       50
aed3ecbc-da60-4119-ac50-e1e1da9cfad1    351     ClinicMAT -Virkon S     373.35  f       1       360.629 f       325
d3c09215-1ec6-4eaa-a567-ba72e1126562    363     ClinicMAT -Virocid 5ltr \N      f       1       \N      f       40
696c0765-a14d-4079-a7b4-e7ef4d43789c    334     ClinicMAT -Vitamin K 20ml       98.7    f       1       98.7    f       98.7
fb21c3a2-af00-4230-a5ed-d10b38efa86c    251     ClinicMAT -Water For Injection (500ml)  5.74    f       1       \N      f       5.735714285714286
a014ad48-c0b5-4156-a7ac-c8d68f426e15    381     ClinicMAT -West Nile Vaccine    87.5    f       1       89.595  f       89.6
cdbf561e-1b4e-488a-a514-bd9542908aaf    325     ClinicMAT -Yellow Lotion        231     f       1       \N      f       231
dc3474e9-1bda-44df-9324-49f155bba5c6    241     ClinicMAT -Zinc Oxide Cream     20.41   f       1       23.295  f       26
67f90537-370a-4255-8d18-2430c609db53    2063    ClinicMAT- 25G Needles 1×100    11      f       1       \N      f       11
abdf7421-68cb-4759-a93d-e201e46bd08e    2525    ClinicMAT- Airway Gel   2952    f       1       220.5   f       181
e5bc518f-d4f8-4fdb-9c1d-3ad433a4ca85    2059    ClinicMAT- Arthramid VET        780     f       1       \N      f       780
3b1ecd08-da34-4f41-94f2-1b28f324e70b    2060    ClinicMAT- Catheter 1.8mm OD x 200cm    62      f       1       62      f       62
8f7ee304-4b52-49ab-8c09-83cb071fb141    2564    ClinicMAT- Good as Gold + Mag 1.5 kg    22.05   f       1       370     f       370
cae5bddc-f06d-435e-9877-15bf7ff35ee3    2527    ClinicMAT- Intibio A2M 30 ML    2952    f       1       1280    f       1280
2e06201f-ef06-4cdb-aafe-2a5c8efaa28d    2566    ClinicMAT- Invokana 300 mg      22.05   f       1       288.5   f       288.5
e6594f6e-5c87-4a9a-8178-02ddc964be1c    2062    ClinicMAT- Spinal needle 18G × 10 inch  \N      f       1       72.65888889     f       70
4d937bc3-50a8-4e48-bfea-1768f0590a61    2514    ClinicMAT- Tornel Equan- Gel 10 g       5       f       1       30      f       30
8e4b4b95-ea34-4fc0-a66f-7ba722952870    2528    ClinicMAT- Vit B1       2952    f       100     59      f       59
21c8b9e0-aa7c-4a91-bfe5-abab90d6d95f    2074    ClinicMAT-Hoofmaker     855     f       1       \N      f       870
5ebde60a-d0a9-4df1-8b15-89887eba36d3    2456    ClinicMAT-Powerflex Equine cohessive Bandage    5       f       1       9       f       9
864b4c1e-c1ef-4e2f-a003-788b93c865c1    2058    ClinicMAT-Sulprim Paste 90      f       1       \N      f       90
04386e34-fa5d-4265-a58a-ef2fbca62073    2654    DETTOL HANDSANIZER 200ml        \N      f       1       42      f       42
53f487e4-6d38-49ac-a4c6-5f84ce1bd8b9    1261    HorseFoodMAT -FIRST CUT AMERICAN TIMOTHY HAY 50 KG. APPROX.     \N      f       \N      2.755   f       3.8
a0125921-9127-4c74-b73a-cde0ec0e67c5    2034    HorseFoodMAT-Meadow Hay \N      f       \N      2.19999994      f       29
b29235dc-4457-44c1-b44a-c10222cb7978    2874    HorseFoodMAT-Meadow Hay 8KG/BALE        \N      f       \N      \N      f       29
f3136351-1cb0-479a-b64b-ac3c0c83f25c    2861    KitchenMAT -Plastic Glass 6 OZ CLEAR 1*1000     \N      f       \N      \N      f       35
48ac9592-3ac7-4b32-a92a-dc80d02c3089    2070    LiverySRV-Premium Package.. Livery      5999    t       \N      \N      f       0
c26507f3-4663-44f8-875e-b629c9064fef    2657    Plusvital Microsponge Powder 500Gm      \N      f       1       105     f       105
191cf3ec-7166-41e4-bf79-0bde02a46bd1    2462    Sponsorship by UAE Federation   \N      f       \N      \N      f       0
9aab19e4-afca-4c26-9e76-2c0f7e99db77    2879    StationaryMAT -PP BOX FILE-4CM FIXED MECHANISM COLOURED \N      f       \N      \N      f       \N
a70a7c46-a9d3-4a86-bd4a-b268b1176712    2878    StationaryMAT -ZEBRA PEN BE-Dx5 0.5MM   \N      f       \N      \N      f       \N
dfd96bd1-726c-41e5-b971-d383fdfb2314    2872    TackMAT -FLY SPRAY FLY FREE 5L  \N      f       \N      \N      f       \N
7c68d963-9cd4-4e8d-8a78-2cedc875cb33    2868    WoodShavingMAT -American pine wood shaving 15kgs        \N      f       \N      \N      f       49
5010a31e-9ea2-40f2-bbae-a6b165c482a0    2036    WoodShavingMAT -GOLDSPAN DUST FREE WOOD SHAVING \N      f       \N      2.62    f       3.93
86263860-7534-42d2-9710-6cd1f26e8d69    2173    ##Third Party Services  \N      f       \N      0       t       0
d09abcb2-9e99-4335-9f08-42f5134f784f    773     AdvertizingMAT -ADEC WHITE CAP  \N      f       \N      15      f       15
a58f0405-6a03-4469-b5ac-049299a9399b    772     AdvertizingMAT -BLUE CAP        \N      f       \N      15      f       15
d85b2514-ca57-455e-96e3-f3e7d7388561    767     AdvertizingMAT -CAP     \N      f       \N      14.5    f       14.5
1b6ad7b2-af6e-4b73-81df-7371e27cfdca    768     AdvertizingMAT -CAP -ADEC       \N      f       \N      17.6564125      f       17.6564125
0ac53015-d1ab-4e3e-bb5e-5d3b244061d0    765     AdvertizingMAT -FLAG    \N      f       \N      130.7638806     f       130
c5134717-9a24-4fdc-8a7a-f90a7124149c    766     AdvertizingMAT -GOLD COATED KEY RING HOLDER     \N      f       \N      9.5     f       9.5
5f71bd53-a628-43de-bd4c-11f2fe73e9ca    774     AdvertizingMAT -ROSETTS – UAE FLAG MODEL WITH PRINTING  \N      f       \N      50.12111111     f       50.12111111111111
1abc2ce2-3831-49bf-8e02-312bb7f90246    771     AdvertizingMAT -TABLE CHESS BOARD       \N      f       \N      32      f       32
679bd921-b6ab-4607-85f2-4353b4866923    2523    AdvertizingMAT -UAE FLAG        \N      f       \N      90      f       90
93e668c7-eb77-4ac8-9865-a28ba7329d19    769     AdvertizingMAT -UAE FLAG BIG    \N      f       \N      72.01571429     f       72.01571428571428
8c191496-3160-4877-97fe-13c3eaba4dc3    770     AdvertizingMAT -UAE FLAG SMALL  \N      f       \N      50.4352 f       50.4352
f68bcc19-225b-4f26-9ec6-b9061c518453    2524    BHS Exams Training Fees Stage 2 – Coach Mock Exam       2500    f       \N      \N      f       0
b570ea79-a3e9-4512-aadf-f35871780fdb    2486    BHS Training Fees Stage 1 – ½ Day – Horse Care Course – Private (Intensive)     4000    f       \N      \N      f       0
d2162879-cd39-4dd6-9c8b-a774986d8f64    2493    BHS Exams s Training Fees Stage 1 – Care Mock Assessment        1100    f       \N      \N      f       0
2251ee4b-d160-466c-8589-f2f295f26b80    2492    BHS Exams s Training Fees Stage 1 – Riding Mock Assessment      500     f       \N      \N      f       0
f2da535b-b290-42b1-a561-4fb38f91d5b7    2495    BHS Exams s Training Fees Stage 2 – Care Mock Assessment        1250    f       \N      \N      f       0
597cde38-6ce8-4c62-8451-de86e7986103    2490    BHS Exams s Training Fees Stage 2 – Horse Care Course – 5 Sessions – Group      1500    f       \N      \N      f       0
9f20d77e-c2bd-4e6d-bcb6-641aed2f3ce5    2494    BHS Exams s Training Fees Stage 2 – Riding Mock Assessment      1100    f       \N      \N      f       0
eedc3a75-99f2-466d-912a-a7a8e2570e24    2496    BHS Exams s Training Fees Stage 3 – Care Mock Assessment        2000    f       \N      \N      f       0
f22c7d4e-0ac1-4417-a7f4-d5f17acee90f    2491    BHS Exams s Training Fees Stage 3 – Horse Care Course – 5 Sessions – Group      2000    f       \N      \N      f       0
590fdc01-b5f5-4bf4-973a-5b56c9283276    2497    BHS Exams s Training Fees Stage 3 – Riding Mock Assessment      2000    f       \N      \N      f       0
c8482c51-286d-40c5-aec0-0d624155956c    2489    BHS Training Fees Stage 1 – Horse Care Course – 4 Sessions – Group (Weekly)     1100    f       \N      \N      f       0
e19977bf-4ccf-4a08-b55e-05fc38d6ffbf    2488    BHS Training Fees Stage 1 – ½ Day – Horse Care Course – Group (Intensive)       1100    f       \N      \N      f       0
0a87f840-08c9-44c7-96de-0d30ccad2d4c    2487    BHS Training Fees Stage 1 – ½ Day – Horse Care Course – Semi-Private (Intensive)        2000    f       \N      \N      f       0
72880829-d949-42b8-a806-28652d000309    2444    BrandingMAT -CLASSY  NOTEBOOK   \N      f       \N      \N      f       110
3eb13ce2-c0ac-4993-90d6-aaf5733309dc    2387    Alvegesic 10 ml 373.35  f       10      145     f       145
f91cea70-f76b-4cd2-986d-de32557da7e7    2251    Air tickets for employees       \N      f       \N      \N      f       \N
70d05639-7b99-4268-be82-f5df9e5e0162    2420    Air tickets for Traveling in Mission    \N      f       \N      \N      f       \N
51407211-0151-48c5-8c8f-82d854eb76e2    2407    Car Lease       \N      f       \N      \N      f       \N
66dbd795-963f-4fa4-9943-13be70bf2e51    734     CleanMAT -DETTOL-500 ML 24 X 1  \N      f       \N      \N      f       \N
38a5a420-36af-4d65-bda0-72d4f1c79945    755     CleanMAT -HAND WASH 5LTR        \N      f       \N      \N      f       \N
ee84ba35-91d6-4b54-b6ff-9c0c27992789    727     CleanMAT -LIQUID HAND SOAP 5 LTR. X 4   \N      f       \N      \N      f       \N
76da4689-cb91-4a28-bac0-2833655cf809    2370    ClinicMAT - Butomidor 10 ml     373.35  f       1       \N      f       \N
6ae4a82f-6762-4c06-83ea-9f6b9c64c240    740     CleanMAT -STEEL GLASS WIPER 35 CM       \N      f       \N      \N      f       \N
3db67244-b68b-4d76-9920-6449a5326a9a    758     CleanMAT -TIDE – 3KG    \N      f       \N      \N      f       \N
e50900a9-d0b7-4b52-9181-1c58bcb9d7fa    743     CleanMAT -TIDE-SML 72 X 1       \N      f       \N      \N      f       \N
532bd63a-eeb3-49f9-bb28-c77a08a14dc3    754     CleanMAT -WASTE BIN METAL       \N      f       \N      \N      f       \N
b26e1e99-5a6e-423d-b2dd-3ee9f09e06bd    748     CleanMAT -WASTE BIN PLASTIC     \N      f       \N      \N      f       \N
603db0f0-3b9b-4969-9d49-8ebcf6253057    712     CleanToolsMAT -TOILET TISSUE BOX        \N      f       \N      \N      f       \N
eea4c447-3cf5-4c62-a21f-34e7ffbccbfa    763     CleanMAT -SCOTCH-BRITE GENERAL PURPOSE WIPE 4/PKT       \N      f       \N      11.1    f       11.1
316f1c9f-c6c7-4912-a789-be73c7b3719c    2213    ClinicMAT -Arthropen vet 250 x 1 (12 pcs in box)        2952    f       1       135.18888889    f       123
bf9e2c42-98a7-41df-a1b3-a900cf1dbc5a    341     ClinicMAT -Butterfly Catheter 16G       \N      f       1       \N      f       \N
cff53858-a896-4f0a-81b5-36eed0bb3572    308     ClinicMAT -Cartrophen (10ml bottle)     \N      f       1       \N      f       \N
30094b6b-8fb2-423a-a966-295ebe7bb01f    354     ClinicMAT -Clipper Blades Size 40 1/10mm        \N      f       1       \N      f       \N
3ba3bc1a-f7e8-4fc6-8719-5114d8ab4f49    309     ClinicMAT -Compagel     \N      f       1       \N      f       \N
970ccfe4-4034-4bd7-ad23-fefc7ffaf758    422     ClinicMAT -Cover Slips 24x50mm (100/box)        \N      f       1       \N      f       \N
e17d7ade-df83-41e9-8fac-3196e9225d84    223     ClinicMAT -Duvaxyn IE -T Plus   \N      f       1       \N      f       \N
995d7c94-118e-473e-8fcb-3cda1e344320    407     ClinicMAT -Equivet Stomach Tube L (19x3000mm)   \N      f       1       \N      f       \N
ccd8e9f3-23c4-4a45-ac32-05ec3198a409    327     ClinicMAT -Eqvalan Paste        \N      f       1       \N      f       \N
94b5861a-d452-40c8-a622-ea70ccd89d6a    333     ClinicMAT -Estroplan    \N      f       1       \N      f       106.75
61a9bb27-ff81-46b2-812a-c1fa8185dadd    254     ClinicMAT -Finadyne (50ml bottle)       \N      f       1       \N      f       \N
2381f7db-6dd1-4b75-b39c-4f4e15a14a5b    405     ClinicMAT -Gut Balancer 400g    \N      f       1       \N      f       \N
0c1730db-38cd-469c-890e-a9856b02f998    230     ClinicMAT -Hyonate 2ml (2pce/box)       \N      f       1       \N      f       \N
319e9811-72f8-4971-8813-361b2f1561dc    428     ClinicMAT -Injectable Paracetamol       \N      f       1       \N      f       \N
172d4576-e624-42ab-b696-749bf8a2decf    313     ClinicMAT -Insol Dermatophyton  \N      f       1       \N      f       \N
0c3f184e-aa77-4966-ad65-c65a3303f04b    266     ClinicMAT -Lasix (10ml vial)    \N      f       1       \N      f       \N
f86c1926-54b7-4e60-9c47-7054875b6243    412     ClinicMAT -Ketamidor 100mg/ml (10ml bottle)     \N      f       10      \N      f       \N
54f3e9bf-b6fd-42d3-aa9d-f2c56cc5897e    225     ClinicMAT -Meflosyl (100ml bottle)      \N      f       100     \N      f       \N
04caca7c-ed73-4ce2-8e1d-c5d9d5be4898    1574    TackMAT -HOOF BRUSH WITH CAP    \N      f       \N      \N      f       \N
d0071cab-cf2b-4c0f-a0d8-8e1c79c70328    253     ClinicMAT -Examination Gloves L (100/Box)       \N      f       1       8.725   f       7
fa4c579d-5b9d-44f9-af91-6ffc52cb0389    434     ClinicMAT -Mitochondrial        261     f       1       261     f       261
f831c7f2-7d65-493c-9c95-71a48f2f1b68    306     ClinicMAT -Omoguard 33g \N      f       1       \N      f       \N
4411200a-511e-4eed-b7cd-75dfa8e80dd9    374     ClinicMAT -PRP Kit      \N      f       1       \N      f       \N
4e2dae52-0d80-42ba-9be2-e9bc1043d54b    272     ClinicMAT -Panacur Paste        \N      f       1       \N      f       \N
ef03ccf4-86d2-4c72-b768-c8d2f57aa9e9    389     ClinicMAT -Preedy Granules      \N      f       1       \N      f       1033.2
e86f8403-90df-4280-b372-ba116c817152    385     ClinicMAT -Protexin Equine Acid Ease 1.5kg      \N      f       1       \N      f       \N
6e767f1c-030d-41d4-bbb2-9a549ef0f311    384     ClinicMAT -Protexin Equine Quick Fix 30ml       \N      f       1       \N      f       \N
2faf269c-6de6-4769-b5cc-2b48c970f958    238     ClinicMAT -Ranitidine Tablets   \N      f       1       \N      f       \N
a2449cfb-a2ab-4b2c-9d3b-bf01576b2a1b    373     ClinicMAT -Respadril 250ml      \N      f       1       \N      f       \N
5e05f220-58d8-494c-845a-d38261a1fb66    417     ClinicMAT -Scalpel Blade (Size 22)      \N      f       1       \N      f       \N
b21545b5-ce3f-4779-9c8e-99d9aa545ca0    240     ClinicMAT -Sedazine Paste       \N      f       1       \N      f       \N
b0ceb4df-1fef-40e9-ab9d-3d0d72bd2e36    320     ClinicMAT -Sedivet      \N      f       1       \N      f       \N
dd9c00f4-33bc-448b-a18e-7b664ad118e4    305     ClinicMAT -Spinal Needle 20G 6" (405211)        \N      f       1       \N      f       \N
9203a1d1-eb16-4348-a112-82e4d39f74dd    370     ClinicMAT -Sungate      \N      f       1       \N      f       \N
45f0c546-3431-4989-bd8a-81a008c81a69    455     ClinicMAT -SURGICAL SCRUB BRUSH 5       f       1       5       f       5
629e0905-b58e-416e-bf41-66b2fa790001    243     ClinicMAT -Surgical Spirit 5ltr 30      f       1       30      f       30
a31af723-23f4-4d89-86f3-09164e75857d    317     ClinicMAT -Terramycin Spray 3.5g        \N      f       1       \N      f       \N
596287c8-91d9-4d75-88b7-cae4465c1aef    260     ClinicMAT -Tildren (10 vials/box)       \N      f       1       \N      f       \N
76be2acb-acb1-4c02-88d0-16c988cc7421    335     ClinicMAT -Vit B12 Inj (30ml bottle)    \N      f       1       \N      f       \N
bc7d7fad-0596-4eda-9de3-3d39b10ed8ea    1756    ClinicSRV -Back Injection - Mesotherapy \N      f       \N      \N      f       0
8374f0e5-1828-40d3-ab45-406105d4f09e    1725    ClinicSRV -Lab - SAA    \N      f       \N      \N      f       0
68b7baab-fb98-4d1a-9f57-f13c29847eee    2402    Commercial Liability Insurance  \N      f       \N      \N      f       \N
374cd60c-5f93-44c6-889d-1161363435ab    2458    consumables for Garage  \N      f       \N      \N      f       \N
e2334512-9e1d-43da-9d8e-dc8616990c24    469     ElectricalMAT -BATTERY AA ENERGIZER     \N      f       \N      \N      f       \N
d9f87bae-2f0a-4c3f-bd14-292ceb8c88ec    468     ElectricalMAT -BATTERY AAA ENERGIZER    \N      f       \N      \N      f       \N
41ec58c5-2466-4216-bda6-9ad23895e002    470     ElectricalMAT -BATTERY C ENERGIZER      \N      f       \N      \N      f       \N
72642d3a-2142-42e0-9436-f0039a055b6f    467     ElectricalMAT -PHILIPS FLOURESCENT 75-85W/35    \N      f       \N      \N      f       \N
c7977de6-02f2-4fac-95bf-649228bdfbc3    2391    Electricy       \N      f       \N      \N      f       \N
104428e7-a884-4ee0-a184-1688d7e3d8b7    2289    Entertainment Shows for Events  \N      f       \N      \N      f       \N
aa71567e-f891-43ba-b356-ef481178ac45    1775    ClinicSRV -Nerve Block - Tibial/Peroneal        \N      f       \N      \N      f       0
1c804c73-dbba-4e1a-9f02-f996513e83cf    2071    EquestrianSRV-Ambulance Service \N      f       \N      \N      f       \N
963a0fec-2d4d-4957-8107-b7d87d86f67a    141     EquestrianSRV-Flags     \N      f       \N      \N      f       \N
56349505-0f02-445c-ba80-b3ef6c722aaa    2219    EquestrianSRV-Media Commentator Service \N      f       \N      \N      f       \N
cd8da237-0a8b-41df-8b51-b9eea0f8b4da    147     EquestrianSRV-METAL BADGES & id Cards  -Track Race      \N      f       \N      \N      f       \N
8f60bf2f-64a7-4314-9816-576e75a4fd57    139     EquestrianSRV-Security guards   \N      f       \N      \N      f       \N
07d96ad2-f534-4e03-aedc-0cd06d0ecdbf    138     EquestrianSRV-Setting up tents  \N      f       \N      \N      f       \N
c99e1950-0228-4294-aab9-8a8530eb8a50    140     EquestrianSRV-Temporary stables \N      f       \N      \N      f       \N
d2871040-5e89-472c-be91-f4bc41a1c253    2316    ERA OUTRIDER Horse Transportation       \N      f       \N      \N      f       \N
a2276f75-9a5e-45ea-94b0-d2aec19fbc86    2297    ERA Staff Allowances - Races    \N      f       \N      \N      f       \N
29498d67-914d-4d14-b40f-e1aaaba3e534    2305    Event Access tags       \N      f       \N      \N      f       \N
739cbdbe-8e4f-4151-afa0-a0fa35865fb7    2571    Event Insurance \N      f       \N      \N      f       \N
a6133f4e-654b-4375-a7e8-785060a0ff09    2457    Event Mis Prizes        \N      f       \N      \N      f       \N
6ce5fcef-2c98-4f5f-8bb4-6361b8ec7078    2175    Event Specialized operators - AV Technician     \N      f       \N      \N      f       \N
3cad3ef2-9f66-4258-897a-a8e3ab259c28    2096    Event Specialized operators - Generator Operator        \N      f       \N      \N      f       \N
aff1199e-08a4-4aa1-a2a8-817e7e42ddfb    2254    Event Specialized operators - GPS Technician    \N      f       \N      \N      f       \N
32856224-ac71-40d1-8b6c-06e5986a45b1    2097    Event Specialized operators - LED Operator      \N      f       \N      \N      f       \N
4a0acc62-faf5-42a9-90d9-9575f415d520    2094    Event Specialized operators - Nomination Management     \N      f       \N      \N      f       \N
2077ac90-dc94-45e2-9f93-dbb68445d0e0    2454    Event Specialized operators - Officials \N      f       \N      \N      f       \N
18c83164-df2c-4a44-b305-75247678d31c    2092    Event Specialized operators - Ticketing \N      f       \N      \N      f       \N
ed145215-4533-4a4a-9943-3baacdf07a3c    143     Event Wrist Band        \N      f       \N      \N      f       \N
529aaf96-bb3a-4e38-b27b-49e433543f91    2281    Events Uniforms \N      f       \N      \N      f       \N
88dcd02e-3fe2-4ad5-90e5-de16e2b043d8    1121    FarrierMAT -ABRASIVE FOAM BLOCK MEDIUM  \N      f       \N      \N      f       \N
e859a0ad-9094-4be3-918b-b3398fc0862f    1155    FarrierMAT -ACR 332 SIZE: 3     \N      f       \N      \N      f       \N
443f235f-0190-4bc4-ae7f-df2d9ad2af82    848     FarrierMAT -ACR ALUMINUM HORSE PLATE 0 FRONT    \N      f       \N      \N      f       \N
e81dbd84-503c-42b6-93fe-6efef440ac2a    968     FarrierMAT -ACR SHOES SIZE NO. 00L      \N      f       \N      \N      f       \N
6306cccc-dd0e-4da7-9a65-9fba0b57b2fe    972     FarrierMAT -ACR SHOES SIZE NO. 2        \N      f       \N      \N      f       \N
cd97adcb-cca1-4cf9-aacb-c4e7c4085697    1183    FarrierMAT -APP-P-AP12 FormaHoof Advanced Polymer       \N      f       \N      \N      f       \N
d8533a6c-77ac-4c43-91b2-882d66e9b5c9    1113    FarrierMAT -APRONS LEATHER      \N      f       \N      \N      f       \N
f5591402-d83c-45f5-9936-cc0613bb6b5f    850     FarrierMAT -BLS BAR HORSE PLATE 4 3/4 FRONT     \N      f       \N      \N      f       \N
df1f9841-2a04-4fd3-aec4-22f2b556e563    2599    FarrierMAT -Diamond Hoof Defender Spray 475 ml  \N      f       \N      \N      f       135
79f45207-6bca-4f62-bc4c-0dd4dd401f12    1138    FarrierMAT -Diamond Gun For Vettec 210cc        \N      f       \N      \N      f       \N
75e715bf-8edb-40a7-b428-4bd7702ac6a5    1164    FarrierMAT -DIAMOND HOOF PUTTY BLACK 1 KG       \N      f       \N      \N      f       \N
c3ba0c21-1b4c-4884-b8af-57effd494f92    1070    FarrierMAT -Driving Hammer      \N      f       \N      \N      f       \N
5c7d262e-78ab-47bd-8de5-342a5ea7023b    1054    FarrierMAT -E4 MUSTAD LIBERTY NAILS 12 X 250    \N      f       \N      \N      f       \N
e3b083a0-3ab7-406b-a96f-8e2970787863    1169    FarrierMAT -EQUILOX 2 OZ        \N      f       \N      \N      f       \N
78211453-bd9d-49ba-9e48-5bc82ca22165    1178    FarrierMAT -EQUILOX STUBBIE 150 \N      f       \N      \N      f       \N
bbedc92e-2d30-40b9-8d80-e7a322651148    1179    FarrierMAT -EQUILOX STUBBIE TIPS        \N      f       \N      \N      f       \N
c8e33ef5-92bd-44ff-9731-b2c400c39a72    1122    FarrierMAT -FARRIER BOOT        \N      f       \N      \N      f       \N
8a38ddff-78ef-41bf-964c-c07921b3ee34    1072    FarrierMAT -Farrier Nipper      \N      f       \N      \N      f       \N
9c54a72a-876b-47e3-b9b5-843816d879db    1185    FarrierMAT -FH-HP-TRK-HND 3 Traction Slimline Size 3    \N      f       \N      \N      f       \N
7f0ff260-110c-4928-b607-9758c11f2b1c    1136    FarrierMAT -FP Clincher HC12    \N      f       \N      \N      f       \N
90edf3f0-b63f-44c4-be0f-d2fac2100c7b    2602    FarrierMAT -Grand Circuit White Lightning 8 oz  \N      f       \N      \N      f       \N
447b6d33-de57-405a-b28d-a5beddf1cfa8    1115    FarrierMAT -HAMMER - SIZE 1100gm        \N      f       \N      \N      f       \N
855d3ee3-4b26-42e0-9a5e-9813034d1e2d    1114    FarrierMAT -HOOF CLINCHER – LOW NAIL    \N      f       \N      \N      f       \N
2f2fc3a9-0c5e-42bf-8107-31c66024e1a4    1071    FarrierMAT -Hoof RASPS  \N      f       \N      \N      f       \N
f591cfd7-e48a-4bea-b787-852f47ec9a2f    810     FarrierMAT -HOOF TESTER XL      \N      f       \N      \N      f       \N
e055f27f-f185-4bbf-8c6d-791528f8683f    1134    FarrierMAT -JB Rounding Hammer 2Lbs     \N      f       \N      \N      f       \N
bb90d77c-b63c-4699-8ec2-b53b1500609b    852     FarrierMAT -KB ALUMINUM PLATE 2T FRONT  \N      f       \N      \N      f       \N
a923ee34-ebf1-4dd6-a75b-c54a5d796def    2601    FarrierMAT -Keratex Hoof Hardener       \N      f       \N      \N      f       \N
703d805e-1c83-48cc-86ab-e7fbaa0e94d5    2600    FarrierMAT -Keratex Hoof Putty  \N      f       \N      \N      f       \N
3ce28152-1f64-4a7c-a433-15805200e5f2    1001    FarrierMAT -KERCHAERT 0 TRIUMPH \N      f       \N      \N      f       \N
fb5f0136-d378-45f6-904c-0dfbc70f039c    998     FarrierMAT -KERCHAERT NO. 7 KINGSPLATE  \N      f       \N      \N      f       \N
9a541baf-9168-4a01-a8aa-b2ba3d2ce011    845     FarrierMAT -KERCHAERT QUARTER CLIP 00 FRONT     \N      f       \N      \N      f       \N
ab663d04-4161-4ac9-861a-6122457e2012    859     FarrierMAT -KNIFE DOULE S       \N      f       \N      \N      f       \N
791d15a5-005c-4984-885a-9b8cd107da45    802     FarrierMAT -KNIFE FROST \N      f       \N      \N      f       \N
538d2e71-861a-4039-a4ec-5deec64016db    1133    FarrierMAT -Knipex Nail Cutter With Heel        \N      f       \N      \N      f       \N
d9e7fa56-d413-44d3-9225-6a069c6192f3    800     FarrierMAT -L.B. BACK 2 CLIPS - NO. 2   \N      f       \N      \N      f       \N
ba661a28-b719-4f74-859c-b92ea877bb95    1056    FarrierMAT -LB BASIC SIZE 4 (25 X 8) FRONT      \N      f       \N      \N      f       \N
58553e87-16c0-41b4-b7ac-5377a66e435f    876     FarrierMAT -LB HORSE SHOE SIZE 2F 25X8 FRONT 10X2       \N      f       \N      \N      f       \N
461f0afb-5e43-4f0b-a6c5-6d1b07f30178    1137    FarrierMAT -Leather Scissors    \N      f       \N      \N      f       \N
751e3a5c-9580-4669-98f2-11aaedf6dc37    894     FarrierMAT -METAL SHOE 1 CLIP FRONT SIZE 1K     \N      f       \N      \N      f       \N
28e104b7-b599-4b9d-8cb4-4e9da75f59d6    908     FarrierMAT -METAL SHOE 2 CLIP BACK SIZE 000     \N      f       \N      \N      f       \N
69b21ed9-a259-4897-9454-adf91e16487e    983     FarrierMAT -MUSTAD NAILS AS17/8 \N      f       \N      \N      f       \N
2e9b049e-e046-4b1d-b370-166c3ae01c4d    1111    FarrierMAT -NAILS PULLER SIZE NP 12     \N      f       \N      \N      f       \N
06391745-d5d1-406d-8d3e-41334f5941e5    853     FarrierMAT -NBS HORSE PLATE 4 F 1X20    \N      f       \N      \N      f       \N
dc252ff0-ce9e-4d73-b970-8508f1c92485    1140    FarrierMAT -NC Cavalry Drive Hammer 10 Oz       \N      f       \N      \N      f       \N
65bc4ab7-5bbe-437e-ac0c-7857ad781bfa    1068    FarrierMAT -Nylon Hammer        \N      f       \N      \N      f       \N
f5309cd7-ca80-4ffb-9bdf-54226c0580cb    1112    FarrierMAT -NYLON HAMMER SIZE 5- 40mm   \N      f       \N      \N      f       \N
3be004ec-ba0c-45c1-9c2e-6fd7311ee036    2591    FarrierMAT -Rounding Hammer (Beanie) – 1¾ lb    \N      f       \N      \N      f       \N
09ac3390-bab7-4161-b287-fc06d5fe665b    1184    FarrierMAT -SOLCLN-500 Red Horse - Sole Cleanse (500ml) \N      f       \N      \N      f       \N
d5b5adc4-d59b-4151-9a4a-fec4d8ea6564    799     FarrierMAT -ST. CROIX FORGE FRONT STEEL - NO. 4 \N      f       \N      \N      f       \N
af9bd86a-2414-414c-ba20-d0155e2ba31e    1033    FarrierMAT -St. Croix Steel 0 size Hind \N      f       \N      \N      f       \N
774b7b07-c374-4204-86b2-92410b2409b1    1030    FarrierMAT -St. Croix Steel 00 size Toe Clip    \N      f       \N      \N      f       \N
29f42e07-b2b2-40a1-b983-aa4f61314f15    1034    FarrierMAT -St. Croix Steel 1 size Hind \N      f       \N      \N      f       \N
c27865b1-301f-4a19-9339-7ba479528949    1037    FarrierMAT -St. Croix Steel 2 size Hind \N      f       \N      \N      f       \N
afedec86-bb61-4429-94c1-9ce0d40e3275    1036    FarrierMAT -St. Croix Steel 2 size Quarter Clip \N      f       \N      \N      f       \N
2ee5296a-8772-47cf-8030-eead99041aaa    1035    FarrierMAT -St. Croix Steel 2 size Toe Clip     \N      f       \N      \N      f       \N
179f2918-1083-4638-8a41-459a5d58c842    1008    FarrierMAT -ST.CROIX FORGE 00F  \N      f       \N      \N      f       \N
86b90550-c4fb-4949-b17e-de014827fdb4    1009    FarrierMAT -ST.CROIX FORGE X-TRA 00F    \N      f       \N      \N      f       \N
229a3a0f-e7c0-403d-99c5-2b9933da9f19    821     FarrierMAT -ST.CROIX FR EVENTER SIZE 00 \N      f       \N      \N      f       \N
b9ec7ef1-68be-457c-82a4-51b27846b0f9    1119    FarrierMAT -TOOL BAG LEATHER    \N      f       \N      \N      f       \N
a6f70930-9c1c-4360-ae8c-99d48157e04c    1126    FarrierMAT -Tool Box Aluminium New York \N      f       \N      \N      f       \N
e62a2cf7-b9fa-484b-b618-f44119db1f63    817     FarrierMAT -TOOTH EXTRACTOR     \N      f       \N      \N      f       \N
47171004-da9d-41b8-a9fb-23e2744595a3    1144    FarrierMAT -VETTEC EQUIPAK      \N      f       \N      \N      f       \N
9318713c-7ef4-40c6-8dd4-295fbfe51758    804     FarrierMAT -VETTEC SUPER FAST (SILICONE)        \N      f       \N      \N      f       \N
a69a86dc-902f-4769-8c07-ef5b23135985    2158    FarrierSRV-  OutSource - 1 Pad  \N      f       \N      \N      f       \N
550b1516-7c68-4bab-ab4f-2a9e256af1a9    2154    FarrierSRV-  OutSource - Full Reset - Reset 4 Steel Shoes       \N      f       \N      \N      f       \N
72fe84c8-2c7b-4fde-a456-efedda62aa22    2152    FarrierSRV-  OutSource - Full Set 4 Steel Shoes \N      f       \N      \N      f       \N
8515e4f5-45e1-4260-bafc-26024b47e00b    2160    FarrierSRV-  OutSource - Remedial Shoeing - full Set    \N      f       \N      \N      f       \N
19843b68-6544-4870-9c90-3d5f925716c4    2157    FarrierSRV-  OutSource - Replace Lost Shoe From same Farrier- Shoe in Hand      \N      f       \N      \N      f       \N
718149fd-abf8-45dd-9c5b-764ee015eb81    2155    FarrierSRV-  OutSource - Replace Lost Shoes - Missing Shoes     \N      f       \N      \N      f       \N
1dd5436b-06b1-4128-8cd5-54b6ee2bfa6d    2156    FarrierSRV-  OutSource - Replace Lost Shoes From another Farrier- Missing Shoes \N      f       \N      \N      f       \N
a1e62162-8a4c-417e-896e-b9d42f8e09bc    2153    FarrierSRV-  OutSource - Shoes Front + Trim Hinds       \N      f       \N      \N      f       \N
e5ed05b2-c01d-4224-9386-f117cb7e67ec    2159    FarrierSRV-  OutSource - Silicone (pre Hoof)    \N      f       \N      \N      f       \N
1fe36885-e3a2-4ae8-b111-28958036a1e1    2038    FarrierSRV-  OutSource Triming - Hoof   \N      f       \N      \N      f       \N
cadc7373-314d-4c6b-b9b2-7b4149570f51    2321    FarrierSRV- Gas \N      f       \N      \N      f       \N
4070abb8-8e32-448d-b642-faafc47d6067    2163    FarrierSRV- OutSource - Hoof Casting - 2 feet   \N      f       \N      \N      f       \N
579ace59-65f2-4aac-b5ee-788854b481fe    2164    FarrierSRV- OutSource - Rasin Application       \N      f       \N      \N      f       \N
9c1f4487-e407-4824-823f-e9924b6d5c6d    2162    FarrierSRV- OutSource - Remedial Shoeing - 1 Shoe Only  \N      f       \N      \N      f       \N
404c0e9a-7817-4754-a9dc-a405101b40ed    2161    FarrierSRV- OutSource - Remedial Shoeing - front Only   \N      f       \N      \N      f       \N
3d7f913d-7e17-44e3-92a3-8a863d127982    2165    FarrierSRV- OutSource - Rubber Shoes - 2 Feet   \N      f       \N      \N      f       \N
e03654bc-5746-4666-ae4e-c16b136baea1    2296    Federation Officials Allowances - Show Jumping  \N      f       \N      \N      f       \N
53a81b1a-a8ab-426d-aa30-5bee7b190d34    2460    First Aid box Materials \N      f       \N      \N      f       \N
4fbfc9e8-6cfb-48c7-99be-deb27af10344    2408    First Aid Training      \N      f       \N      \N      f       \N
8c913417-dac4-450e-8afd-cd6c3ee98fef    2269    General Labor Supply    \N      f       \N      \N      f       \N
86d9dc05-7973-4f41-91fa-9293e2caaacf    2290    Horse Tracking System   \N      f       \N      \N      f       \N
2ef866b9-f766-4111-bdea-bcc52e4e5837    1311    HorseFoodMAT - Eclipse Haylage Animal feed 20 Kg BAG    \N      f       \N      \N      f       \N
c9db14d1-e655-440a-bcbf-ebf45de12da1    1266    HorseFoodMAT -1.5 KG PLUSVITAL VITAMIN E        \N      f       \N      \N      f       \N
b15e457e-e354-409e-abed-83c4355a32a0    1265    HorseFoodMAT -2 KG PLUSVITAL ELEKTROLYTE        \N      f       \N      \N      f       \N
92506494-5885-4e35-a14e-75dcb0fe7d57    1303    HorseFoodMAT -2nd CUT AMERICAN TIMOTHY HAY      \N      f       \N      \N      f       \N
2a33fa40-5ad9-4ae7-b634-d6d94f09714b    1263    HorseFoodMAT -5 LTR. PLUSVITAL BREEDING SYRUP   \N      f       \N      \N      f       \N
22da54ee-a278-4e30-9894-25c254a1e90c    1264    HorseFoodMAT -6 KG PLUSVITAL VITAMIN DRY BREEDING       \N      f       \N      \N      f       \N
40d501f4-e457-45b1-bdfa-02e7ddb8a8a4    1269    HorseFoodMAT -ACCEL LIFE TIME 10LB. BUCKET      \N      f       \N      \N      f       \N
0ef62194-5a72-4daa-bd99-6a7ffb509c95    1191    HorseFoodMAT -AUSTRALIAN OATEN HAY-27K  \N      f       \N      \N      f       \N
8b17eb6e-5b40-4723-9a8b-7a4f61607057    1320    HorseFoodMAT -B- Complete Formula 2.5 Tubs      \N      f       \N      \N      f       \N
9bed9883-6955-4f1d-9f8a-88ded8fd0911    997     FarrierMAT -VICTORY 2EC \N      f       \N      10      f       10
d8ddfdcb-f052-4635-a484-373efd32d29b    1322    HorseFoodMAT -Baileys Every Day High Fibre Cubes 20 kg  \N      f       \N      \N      f       \N
e5177541-8d40-4fa9-ab72-e6790963541d    1283    HorseFoodMAT -CARRON OIL – 20 LTR       \N      f       \N      \N      f       \N
60a3fa2d-008c-4df9-9854-fdf05f861b58    1275    HorseFoodMAT -CAVALOR ENDURIX   \N      f       \N      \N      f       \N
4e0e8da3-03d4-44b0-b940-5cad7b1a562d    1276    HorseFoodMAT -CAVALOR PERFOMIX  \N      f       \N      \N      f       \N
ebbedde6-7733-4de3-adef-11010163ccb8    1273    HorseFoodMAT -CAVALORE MASH & MIX       \N      f       \N      \N      f       \N
b86a7f3c-2afe-4205-a706-24c73f21c34b    1306    HorseFoodMAT -COMPETITION MIX 12%- RED MILLS 20Kg/Bag   \N      f       \N      \N      f       \N
e4ed6cf6-7eee-4e36-a097-c72e2c1ccb46    1202    HorseFoodMAT -COMPITIION MIX 20 KG.RESPONSE INSTANT ENERGY      \N      f       \N      \N      f       \N
e7c41c42-3468-44b2-86b2-7a80b344f274    1216    HorseFoodMAT -COOL MIX = 20KG   \N      f       \N      \N      f       \N
f598852f-9a45-4c7e-812c-eed8d56fd10b    1219    HorseFoodMAT -COOL PERFORMER-20 KG      \N      f       \N      \N      f       \N
fe0ba925-221b-4699-b154-a689155d5503    1204    HorseFoodMAT -DENGIE ALFA A ORGINAL-20 KG       \N      f       \N      \N      f       \N
b2fe282e-56cc-4e4d-9c6f-3010207ef4bb    1243    HorseFoodMAT -DERMOLINE STOCKHOLM TAR 500 ML.   \N      f       \N      \N      f       \N
ceab0ddb-3efe-4f03-827b-32d0df68a5c4    1205    HorseFoodMAT -DI CALCIUM PHOSPHATE-30LBS        \N      f       \N      \N      f       \N
65007250-76ef-4ff0-80e7-2eda2726d024    1232    HorseFoodMAT -DI-CALCIUM PHOSPHATE - 20 LBS     \N      f       \N      \N      f       \N
03124df5-7bf6-401c-ac23-b4986de0c755    1236    HorseFoodMAT -DUVAXIN IET PLUS  \N      f       \N      \N      f       \N
a6326daa-5a1b-464a-88eb-4f3dc2db597b    1198    HorseFoodMAT -EDHYA FORM 18 KGS \N      f       \N      \N      f       \N
a4f9dc1d-4391-498f-a532-c6e8ae158883    1242    HorseFoodMAT -ELECTRODEX- 5 LB  \N      f       \N      \N      f       \N
7c454f8f-9051-4dd8-8486-b98da5053b04    1190    HorseFoodMAT -ELECTRODEX-30L    \N      f       \N      \N      f       \N
3d190fbe-6416-48f5-8a88-e902964e91c0    1256    HorseFoodMAT -ELECTROLYTE (PREQUINE LYTE 4 KG.) \N      f       \N      \N      f       \N
4df1af82-08a6-47a9-9765-a602c7f95f4f    1296    HorseFoodMAT -EMMA LIFE 2.5 KG  \N      f       \N      \N      f       \N
3bb9cb39-2f75-4a74-97f6-0698e7a133e2    1301    HorseFoodMAT -ENDURANCE MIX - 20KG - RED MILLS  \N      f       \N      \N      f       \N
5a2f64de-d715-4d5f-aa55-f2ca08c30c29    1233    HorseFoodMAT -ENERGIDEX-500ML   \N      f       \N      \N      f       \N
f5a1b4e5-3a1b-496e-8f21-9b6bfa69c14c    1238    HorseFoodMAT -EQUI STRATH YEAST SUPPLEMENT      \N      f       \N      \N      f       \N
b8e43e7b-928a-4909-91f7-617145a6c9e9    1286    HorseFoodMAT -EQUIJEWEL 20KG    \N      f       \N      \N      f       \N
8ef42f1e-e1a8-4a5f-b6cf-da53e2fa8fd8    1201    HorseFoodMAT -EQUJEWEL RICE BARN-20K    \N      f       \N      \N      f       \N
fb373045-b613-4cd4-a2a0-d3b89060efa6    1298    HorseFoodMAT -FITMIN BRONCHIAL  \N      f       \N      \N      f       \N
23752f80-f15d-4cad-8b54-511595d8e0dc    1309    HorseFoodMAT -Garlic Powder 1 Kg        \N      f       \N      \N      f       \N
99941912-239a-4ade-a3bf-6aa08abe7165    1209    HorseFoodMAT -GARLIC POWDER 5 KG        \N      f       \N      \N      f       \N
385fb94e-f678-4514-a854-891d2245a81b    1220    HorseFoodMAT -GARLIC POWDER HILTON HERBS 12.5 KG        \N      f       \N      \N      f       \N
7061bcc8-91ae-4984-9252-0f2ad7d6e5e9    1272    HorseFoodMAT -H350-ENDURANCE FEED-25KG  \N      f       \N      \N      f       \N
2b7bcbaf-35df-4ac5-9342-a6dc4023b0ee    1315    HorseFoodMAT -Havens Cool Mix 20Kg      \N      f       \N      \N      f       \N
257d86a7-1828-423a-b8e5-74eeafcc184f    1314    HorseFoodMAT -Havens Dravers Brok 20Kg  \N      f       \N      \N      f       \N
7b68cb2f-1c4a-49a7-8272-7d5acc7250d7    1228    HorseFoodMAT -HEPAPHYT CLEANSING FORMULA-10 KG  \N      f       \N      \N      f       \N
2df10cee-da58-4530-8279-8a832e768bd6    1211    HorseFoodMAT -HILTON EXTRA MILE- 1 LTR  \N      f       \N      \N      f       \N
e64e3157-a31b-4c74-9487-8b9d5669793b    1196    HorseFoodMAT -HILTON HEPAPHYTE CLEANSING FORMULA - 10KG \N      f       \N      \N      f       \N
f4123e57-b110-4634-aa3c-9f0217dd14c4    1215    HorseFoodMAT -HILTON HERBS GARLIC POWDER 12.5KG \N      f       \N      \N      f       \N
3c4c8b11-d651-4af0-a974-2dacae27d157    1189    HorseFoodMAT -HILTON HIMALAYAN BABY SALT - 3KG  \N      f       \N      \N      f       \N
54a5ffa9-478f-4672-9c01-5a2e07bab945    1252    HorseFoodMAT -HIMALAYAN MINERAL SALT LICK 2 KG. \N      f       \N      \N      f       \N
fbb23b61-0b7a-4e3d-815c-4445f7da48d2    1297    HorseFoodMAT -HITARGO ENERGY    \N      f       \N      \N      f       \N
d12cf27a-10df-4bc0-8b94-8e20890850f3    1259    HorseFoodMAT -HOOF DRESSING 5 LTR (KEVIN BACON'S)       \N      f       \N      \N      f       \N
5f53b98c-0167-46a1-9634-6859c19b9d5f    1221    HorseFoodMAT -HORSE & PONY CUBES-20 KG  \N      f       \N      \N      f       \N
c321dff8-f51c-4679-9357-0a02e1661681    1255    HorseFoodMAT -ICE POULTICE 20 KG.       \N      f       \N      \N      f       \N
dfcbb393-a63e-4286-b934-fc85052ddded    1253    HorseFoodMAT -ICE TIGHT POULTICE 7.5 LBS        \N      f       \N      \N      f       \N
4667f762-7147-42e0-bf23-243853f89198    1223    HorseFoodMAT -KER FEED-50LB     \N      f       \N      \N      f       \N
a61657d5-bf33-442a-9cf5-53cf4a651ff1    1257    HorseFoodMAT -LIKE ICE 11 KG. (POULTICE)        \N      f       \N      \N      f       \N
eb72e248-9217-4856-a5e2-8088db780deb    1302    HorseFoodMAT -LINSEED OIL 5L    \N      f       \N      \N      f       \N
0272d179-a72c-468d-85b8-7a9da1442eba    1312    HorseFoodMAT -LIQUID PARAFFIN OIL 5 LTR \N      f       \N      \N      f       \N
8c424723-699c-411e-aa67-f6bccf89d449    1248    HorseFoodMAT -LOCAL HAY 1X8 450KG.      \N      f       \N      \N      f       \N
175fa110-a378-4bfe-9b5c-9d251a7f9475    1258    HorseFoodMAT -LOCAL HAY 400 KG. \N      f       \N      \N      f       \N
51f15b9d-e9e1-4fc2-85bf-24271cd941d0    1285    HorseFoodMAT -LOCAL HAY 425 KG  \N      f       \N      \N      f       \N
e51bdcb5-ed23-4866-8aea-e0660f94712a    1249    HorseFoodMAT -LOCAL HAY 550 KG  \N      f       \N      \N      f       \N
2d01ecae-dfa0-4c02-aead-730d072a1cf7    1260    HorseFoodMAT -LOCAL HAY 700 KG. \N      f       \N      \N      f       \N
bf32e2f7-28b1-487c-846b-e1de19534aab    1284    HorseFoodMAT -LOCAL HAY 725 KG  \N      f       \N      \N      f       \N
7ad4739a-da5f-47e0-a136-bbad062349ab    1280    HorseFoodMAT -LOCAL HAY 750 KG  \N      f       \N      \N      f       \N
f4400a3a-a8b2-4e5e-a492-00ba7487ec59    1277    HorseFoodMAT -LOCAL HAY 850KG   \N      f       \N      \N      f       \N
3715b737-b64a-4025-b8f9-69848aaaca7f    1305    HorseFoodMAT -LOCAL HAY ALFALFA JET 520KG       \N      f       \N      \N      f       \N
14387925-62d9-461a-bbc3-1a6529b6d2e1    1319    HorseFoodMAT -LOCAL HAY BUNDLE  \N      f       \N      \N      f       \N
e50b192e-46e1-4eda-96ae-73347efff0eb    1237    HorseFoodMAT -LOCAL HAY ROLL 180KG      \N      f       \N      \N      f       \N
83dc76d6-c6e6-479a-bdc0-b987216f696f    1290    HorseFoodMAT -LOCAL HAY ROLL 325 KG     \N      f       \N      \N      f       \N
0ce9e376-e83b-42bb-a013-59667f330983    1270    HorseFoodMAT -LOCAL HAY ROLL 350KG      \N      f       \N      \N      f       \N
65883907-de85-48c1-8da4-ff2443223ee7    1250    HorseFoodMAT -LOCAL HAY ROLL 500 KG     \N      f       \N      \N      f       \N
48a19c5c-5f1a-4eb5-b63c-bd33ba1c09cb    1291    HorseFoodMAT -LOCAL HAY ROLL 525 KG     \N      f       \N      \N      f       \N
15349acd-2d91-416c-8d93-d847eec012e2    1281    HorseFoodMAT -LOCAL HAY ROLL 600 KG     \N      f       \N      \N      f       \N
dbd61ef0-6745-4011-95b9-7904ac011b74    1287    HorseFoodMAT -LOCAL HAY ROLL 625 KG     \N      f       \N      \N      f       \N
bf5ed34c-2d76-4f2e-b16a-f361e99fc922    1251    HorseFoodMAT -LOCAL HAY ROLL 650 KG     \N      f       \N      \N      f       \N
facd6560-76ca-49e6-ac6b-ee2d9e80882d    1271    HorseFoodMAT -LOCAL HAY ROLL 800KG      \N      f       \N      \N      f       \N
cf763113-f7fb-42dc-8209-9d3518223384    1225    HorseFoodMAT -LOCAL HAY ROLL-180KG      \N      f       \N      \N      f       \N
84f562d2-e6d8-4754-a4b2-7ff612c2369b    1300    HorseFoodMAT -MARATHON19 - 20KG - RED MILLS     \N      f       \N      \N      f       \N
e9d19495-2a61-4af7-93cf-d53894ccb550    1213    HorseFoodMAT -MITAVITE BREEDA-22.5K     \N      f       \N      \N      f       \N
4172bdcf-f415-4fb0-848f-d7b28f3855a8    1199    HorseFoodMAT -MITAVITE ENDURA WIN-22.5K \N      f       \N      \N      f       \N
435963fd-e7cb-45b3-bb06-f185180376d1    1218    HorseFoodMAT -MITAVITE FORMULA 3        \N      f       \N      \N      f       \N
c9564f41-4ca7-4185-90be-3cb0ffd8f51d    1210    HorseFoodMAT -MITAVITE PRO SPORT-22.5 KG        \N      f       \N      \N      f       \N
c404f38b-3e42-42d4-a9c6-9cbddab8e00f    1262    HorseFoodMAT -MITAVITE PROSPORT 20 KG.  \N      f       \N      \N      f       \N
a6e5a09c-c716-46b0-8428-4c3b2db5d31b    1226    HorseFoodMAT -MITAVITE RACE ON & WIN 25 KG      \N      f       \N      \N      f       \N
bd39d09b-6fea-4269-9639-604174d92498    1227    HorseFoodMAT -MITAVITE TURBO SUSTAINA-22.5 KG   \N      f       \N      \N      f       \N
b8626087-737d-4ca1-86ba-009f791ddb5f    1203    HorseFoodMAT -MITAVITE XLR8     \N      f       \N      \N      f       \N
dbfca66f-38b5-42d0-8c34-20151d5af2c9    1229    HorseFoodMAT -MOLASSES-35KG     \N      f       \N      \N      f       \N
f9b4385c-4f7a-4be9-a483-49e5e55a2110    1230    HorseFoodMAT -MUMTAZ OIL        \N      f       \N      \N      f       \N
2bb5e63f-00c0-42a8-bb5f-7e6f3778b1ad    1195    HorseFoodMAT -NATURAL GLOW STABLIZED RICE BRAN  \N      f       \N      \N      f       \N
9f86a9dc-8584-47d9-819c-1f37c1c73abe    1197    HorseFoodMAT -OK OIL-11L        \N      f       \N      \N      f       \N
71333535-44c9-443c-acd3-1662593f6796    1274    HorseFoodMAT -OLIVE OIL TIN     \N      f       \N      \N      f       \N
ee179d03-598b-4800-9cf7-48f756ac25f6    1310    HorseFoodMAT -OPTIMAL GROWTH FOMULA 18+ - 20 KG \N      f       \N      \N      f       \N
d3c733c1-aef7-47ce-9922-626136b5831c    1268    HorseFoodMAT -ORYZOL EXTRA 4KG. BUCKET  \N      f       \N      \N      f       \N
7aece159-cc27-486b-8d84-753f87938da7    1295    HorseFoodMAT -P - BLOCK ALSABOOK – 600g \N      f       \N      \N      f       \N
3bc0118a-bd7b-4b0e-b2d7-6f4006c7ecbc    1192    HorseFoodMAT -PERFORMA 3 OIL- 20 LTR    \N      f       \N      \N      f       \N
1cb19515-db5a-4ad2-a52d-d8279d41d6f8    1224    HorseFoodMAT -PERFORMA3 OIL-5 LTR       \N      f       \N      \N      f       \N
ed30f2d8-2eea-4b61-b779-19e30060842f    1308    HorseFoodMAT -Plusvital E Dash 1.5 Kg   \N      f       \N      \N      f       \N
0ac7c8bf-789f-4ef2-9e2e-6b630d3de3b6    1235    HorseFoodMAT -POULTICE LEMON    \N      f       \N      \N      f       \N
ae9604e8-6200-4684-9565-8ab0663da81a    1278    HorseFoodMAT -PRO ENERGY PASTE  \N      f       \N      \N      f       \N
815a8dfa-4211-4150-8049-690c7f20d9a5    1324    HorseFoodMAT -RED MILLS 10% ARABIAN MAINTENANCE FEED 20 KG/BAG  \N      f       \N      \N      f       \N
ad5a08e8-9f22-470a-9ed1-8057ad7e461a    1323    HorseFoodMAT -RED MILLS 10% COOL N COOKED MIX 20 KG/BAG \N      f       \N      \N      f       \N
d5cd5fa3-2154-4cdc-ad29-060a06b7adab    1288    HorseFoodMAT -SARACEN ENDURO 100 – 20KG \N      f       \N      \N      f       \N
6f617a29-6e18-4db2-9204-c6d34a8fa737    1292    HorseFoodMAT -SARACEN SHOW IMPROVER 20KG        \N      f       \N      \N      f       \N
f6c9fd33-c57e-4ea2-8171-1804047dfe05    1206    HorseFoodMAT -STAY SOUND POULITCE-30LBS \N      f       \N      \N      f       \N
9e24000d-4a45-4095-964b-e26b16380bc2    1294    HorseFoodMAT -STRESS DEX 20LBS  \N      f       \N      \N      f       \N
c11f8484-2071-4650-83e6-5a5db38f03fd    1240    HorseFoodMAT -SU-PER BIOTIN PLUS 12.5 LBS       \N      f       \N      \N      f       \N
9ff52f8e-1dc3-429b-9145-286be1850f7e    1239    HorseFoodMAT -SU-PER FARRIER SUPP. 5 LBS.       \N      f       \N      \N      f       \N
45df17c6-75f6-40bf-a29a-152a5a99f51e    1241    HorseFoodMAT -SU-PER PINE TAR   \N      f       \N      \N      f       \N
6bc8279b-43f3-4f8d-8cd7-8458f743a968    1254    HorseFoodMAT -SUP-PER POULTICE 10.3KG   \N      f       \N      \N      f       \N
0b5e1695-ae39-467b-a10e-bc01527b5605    1231    HorseFoodMAT -TWYDIL ARTRIDIL - 50GM 90 SACHET/BOX      \N      f       \N      \N      f       \N
89cf4164-915b-46ae-b20a-bfa8e62d8c73    1234    HorseFoodMAT -TWYDIL CALMIN 50 GM       \N      f       \N      \N      f       \N
e644cc65-91a5-4835-9839-20b9bbc6b28b    1217    HorseFoodMAT -TWYDIL ELECTROLYTES       \N      f       \N      \N      f       \N
2be5e7fe-5767-488b-8e8f-3d97b0c430c5    1244    HorseFoodMAT -TWYDIL GROWTH 3 KG ( PKT )        \N      f       \N      \N      f       \N
0b280040-df3d-4c3a-b999-f89272e32019    1279    HorseFoodMAT -TWYDIL HEMATINIC  \N      f       \N      \N      f       \N
fc29754c-cce9-4b4d-9bbc-bea8d6b3960e    1193    HorseFoodMAT -TWYDIL HEMOPAR - 1 LTR    \N      f       \N      \N      f       \N
9059ac2b-d82c-4fa7-89f6-a96ed9b37ee0    1214    HorseFoodMAT -TWYDIL PROTECT PLUS - 60GM        \N      f       \N      \N      f       \N
8198deaa-25b7-44ad-bb78-4efa4f6e14ca    1247    HorseFoodMAT -TWYDIL STOMACARE 50GRM SYRINGE    \N      f       \N      \N      f       \N
94bd32f3-c732-4eb5-8105-29680fb4ecd4    1282    HorseFoodMAT -TWYDIL TWYBLID- 100 SACHET        \N      f       \N      \N      f       \N
a6f275b3-29a7-46b0-8e83-e6b27d7200b6    1246    HorseFoodMAT -TWYDIL VIGORADE 50GRM SACHET      \N      f       \N      \N      f       \N
fede779f-e3f7-4ecf-ab28-a8d295cc58ef    1289    HorseFoodMAT -UPTITE POULTICE - 8.6KG   \N      f       \N      \N      f       \N
e8ab4ae3-a08b-49a9-989e-257585028ee1    1293    HorseFoodMAT -VEGETABLE OIL 18 LTR      \N      f       \N      \N      f       \N
3854d84e-c581-45c5-9c7b-ecae8c23d5df    1267    HorseFoodMAT -WHOLE BARLEY      \N      f       \N      \N      f       \N
aeb52325-7985-4b1e-8b5b-9c4cc3515a20    2463    Ice Box \N      f       \N      \N      f       \N
7cbddc0b-955f-4563-95ea-78874f40bbeb    2293    Infrastructures / Land  Survey  \N      f       \N      \N      f       \N
d505f17d-626f-424c-a2e9-94cb0a7524cd    2252    Installation and dismantling of assets for event preparation.   \N      f       \N      \N      f       \N
6f9fc64e-1ae1-4fcb-b9bf-835e97fb9f64    488     KitchenMAT - SPOON      \N      f       \N      \N      f       \N
feb508ff-80c7-4490-97db-e289314bb939    494     KitchenMAT -AL AIN WATER 24 X 250ML     \N      f       \N      \N      f       \N
49a47cb1-32d1-4b63-84ed-f486e569bb8b    518     KitchenMAT -AL AIN WATER 24X500 ML      \N      f       \N      \N      f       \N
6bbc63f9-762c-4fbb-af52-d5bdd6198966    495     KitchenMAT -ALAIN WATER 12 X 1.5 LTR    \N      f       \N      \N      f       \N
b2eeb7d5-a0f4-42cc-986f-c2c679bdcd95    508     KitchenMAT -CLING FILM - PLASTIC ROLL   \N      f       \N      \N      f       \N
ea8476da-a838-4fae-90b4-864dd4aff460    498     KitchenMAT -DISPOSABLE CUP 1 X 1000     \N      f       \N      \N      f       \N
6f800f88-782c-4014-a320-dc7e18f08821    527     KitchenMAT -FRESH JUICE GRAPE– FLORIDA – 300ml  \N      f       \N      \N      f       \N
ee6b7359-4718-4ae6-b05d-6cb8d8507695    506     KitchenMAT -LONG LIFE MILK 12x1LTR      \N      f       \N      \N      f       \N
61e4722c-8789-4b09-b7ba-0d10da4d00f4    519     KitchenMAT -NESCAFE 3 IN 1 (1x24)       \N      f       \N      \N      f       \N
95f08abf-cc89-446a-bec2-1a97e61d5224    522     KitchenMAT -Red Bull 1*24       \N      f       \N      \N      f       \N
8b8eb178-c4fe-499f-8061-e7082d45b155    500     KitchenMAT -SUGAR CUBES \N      f       \N      \N      f       \N
654ee8b9-53a6-4f99-8580-f03ffc9eb3f4    511     KitchenMAT -TEA STRAINER BIG    \N      f       \N      \N      f       \N
9da1589c-b7a6-4020-8c69-0410da37281e    510     KitchenMAT -TEA STRAINER SMALL  \N      f       \N      \N      f       \N
b342cae6-2723-4474-b3b0-893a7d5a3bc1    521     KitchenMAT -Tonic water 1*24    \N      f       \N      \N      f       \N
25ee20ea-79a9-4b00-98a7-2ecba5850853    789     KitchenToolsMAT -Aluminium Cooking Pot 22cm     \N      f       \N      \N      f       \N
aba913b2-fb3d-4887-85bc-e55a99e775b1    788     KitchenToolsMAT -Aluminium Cooking Pot 26cm     \N      f       \N      \N      f       \N
c057f78c-e110-4724-bbae-e33125192342    778     KitchenToolsMAT -BED COVER & SHEET      \N      f       \N      \N      f       \N
b5c19bcb-4dbf-486c-9cd7-34e06a5e4f97    779     KitchenToolsMAT -BED SIDE TABLE \N      f       \N      \N      f       \N
55b7daa7-36ec-4ac3-a390-a2666dffbfab    781     KitchenToolsMAT -BLANKET SINGLE \N      f       \N      \N      f       \N
b223de92-9db1-4e20-aaaf-a3cb5d94ee1d    782     KitchenToolsMAT -BLANKET-DOUBLE \N      f       \N      \N      f       \N
ec44a129-68ae-4cf7-9eae-6db9f66cd306    791     KitchenToolsMAT -Cooking Spoon RAJ 20cm \N      f       \N      \N      f       \N
f5fd7492-d074-4d50-b070-e0c69d3e8224    790     KitchenToolsMAT -Cooking Spoon RAJ 30cm \N      f       \N      \N      f       \N
9a0b11c7-1f12-4712-9d41-f7b97fc94392    786     KitchenToolsMAT -DRINKING GLASS \N      f       \N      \N      f       \N
7c86d748-4c8b-43e6-ac2a-9d995d9cc220    785     KitchenToolsMAT -FORK   \N      f       \N      \N      f       \N
01a4c366-0c00-4f0c-b57d-ee2f4e18ec3e    796     KitchenToolsMAT -Knife 10" Brazil       \N      f       \N      \N      f       \N
61fc466e-3df0-4154-ae99-468b13a11f44    787     KitchenToolsMAT -MEDICAL BED    \N      f       \N      \N      f       \N
c9bdb938-ef12-43fd-b59d-8a35ecb62ee5    795     KitchenToolsMAT -Sauce Pan With Handle 20 cm    \N      f       \N      \N      f       \N
8080aee7-77c6-453e-939a-9a0275581b40    794     KitchenToolsMAT -Soup Bowl      \N      f       \N      \N      f       \N
81df6efc-82f2-487a-bd7d-7514dd7fc554    784     KitchenToolsMAT -TABLE SPOON    \N      f       \N      \N      f       \N
f061c704-684d-4b0f-84f5-543abd101cc9    792     KitchenToolsMAT -Tea Cup & Saucer Ceramic       \N      f       \N      \N      f       \N
3e3fc26e-1da4-4c64-bed7-ba79a671c337    793     KitchenToolsMAT -Water Class    \N      f       \N      \N      f       \N
ea4e7dd2-1840-4827-a90b-7e4c9f6b3a8d    118     MaintenanceSRV-##General        \N      f       \N      \N      f       \N
37b8e046-e256-4425-b281-4e969c1aac63    2230    MaintenanceSRV-##Infrastructure \N      f       \N      \N      f       \N
a887aaf9-cdda-41ce-805d-ba6ee1ce85ca    2238    MaintenanceSRV-Agriculture machinery and equipment      \N      f       \N      \N      f       \N
e8ea5cae-b30e-4eb8-a960-1545310fb783    2229    MaintenanceSRV-Buildings        \N      f       \N      \N      f       \N
b28e7181-e8c5-4224-be67-40178a479bcb    2233    MaintenanceSRV-Distribution and Conditioning Equipment  \N      f       \N      \N      f       \N
d37fa443-7e26-4c59-8a2f-e8614d11aa45    2234    MaintenanceSRV-Electrical and Power Generation  \N      f       \N      \N      f       \N
e72ce69f-9c5d-4d4e-b744-50c43bc3a00b    2239    MaintenanceSRV-Equestrian Equipment     \N      f       \N      \N      f       \N
1cacbf37-b126-42e4-bf2e-4b6cb3149b9c    2231    MaintenanceSRV-Furniture and Fixtures   \N      f       \N      \N      f       \N
bafea4e2-198b-4b99-9742-64262d93c312    2232    MaintenanceSRV-Information Technology Assets    \N      f       \N      \N      f       \N
f2d10d8f-db23-47c8-92b3-debafc78e7c3    121     MaintenanceSRV-Light Machines Services  \N      f       \N      \N      f       \N
eae2ce80-f912-43ec-a2c5-b2a856f016db    117     MaintenanceSRV-Machines \N      f       \N      \N      f       \N
af5c0beb-ce4a-43f9-b692-c5c212c44823    2235    MaintenanceSRV-Medical Equipment        \N      f       \N      \N      f       \N
200c8c65-3098-46c5-b9fa-06e9ea092ea4    2236    MaintenanceSRV-Plants Maintenance       \N      f       \N      \N      f       \N
feeb959f-0a7c-437c-a1f5-3b719ce38b52    2127    MaintenanceSRV-Tyres    \N      f       \N      \N      f       \N
2fc7ae77-9cb6-4c1a-9c26-ef2bac3d844d    2072    MaintenanceSRV-Vehicles Maintenance     \N      f       \N      \N      f       \N
30bb1163-46cf-48f4-af7c-742397e3d1e5    2180    MaintenanceSRV-Vehicles Registeration and Renewal       \N      f       \N      \N      f       \N
d9d4f875-95b6-4a94-9bff-a8a12b142df4    2634    Mall Staff Uniform      \N      f       \N      \N      f       \N
f1e1eacd-e0cf-44de-aaea-9f7db2803d04    2633    Mall_ LPG system maintenance    \N      f       \N      \N      f       \N
1cc9339e-4433-48ab-b71a-2e8a029b03a9    2676    Merch Store Purchased Items     \N      f       \N      \N      f       \N
f90e1236-0aff-4699-a9ff-f08c2224f5c3    2209    OtherSRV- Branding Minor Decoration     \N      f       \N      \N      f       \N
ff8e43d1-d6a9-4cb2-86f8-5ab6bffa0820    2250    OtherSRV- Entry Fees    \N      f       \N      \N      f       \N
5b172e97-45a1-48dd-8c3d-04f326a11957    2306    KitchenToolsMAT -Cosmoplast Arm Chair   \N      f       \N      \N      f       35
59fa15d9-b71a-4fb9-8c93-c6f29c21728b    777     KitchenToolsMAT -PILLOW \N      f       \N      15      f       65
d744b5a8-7bda-43c1-8994-518ee1904d31    2240    OtherSRV- Flight ticket \N      f       \N      \N      f       \N
be5315f6-5248-4d04-aca9-17997b64dbc1    2242    OtherSRV- Hotel booking \N      f       \N      \N      f       \N
46499606-1a9a-4bf4-9cd9-913b84ca862e    2364    OtherSRV- Parking Charges       \N      f       \N      \N      f       \N
180ec834-ccd9-45a0-818d-131a7e1322ae    2270    OtherSRV- Premises Rent \N      f       \N      \N      f       \N
b9cad8e4-a85d-4b9c-930e-74fdea380823    2241    OtherSRV- Transportation        \N      f       \N      \N      f       \N
503c5ca3-9690-4bc0-b35b-69d38d058049    129     OtherSRV-##Advertising  \N      f       \N      \N      f       \N
b406379a-7072-4b25-928b-bd2a924e446f    2115    OtherSRV-##Marketing and Advertising    \N      f       \N      \N      f       \N
e41fbe9e-b656-4f89-b4aa-c50c5883e21b    135     OtherSRV-Air Horse Transportation Services      \N      f       \N      \N      f       \N
e6feca95-3f24-4d17-b718-d0912a79d787    2325    OtherSRV-Best Appearance Award  \N      f       \N      \N      f       \N
bfcdc55d-70ac-4286-991b-0b4cb4d7c4a3    2326    OtherSRV-Best Photography       \N      f       \N      \N      f       \N
7338eb32-dc04-4b62-b22a-dde7f62d9a92    2089    OtherSRV-Catering       \N      f       \N      \N      f       \N
b2aaf2bc-db8a-41ad-9d71-d13d2e1824ad    2507    OtherSRV-Catering For Staff     \N      f       \N      \N      f       \N
d8c2213b-e3a6-4dc9-a090-d8ded8d42875    127     OtherSRV-Cleaning Services      \N      f       \N      \N      f       \N
ac9c9347-5245-4882-b7ce-f056594edabb    2191    OtherSRV-Demolition     \N      f       \N      \N      f       \N
80058ac0-acf7-41d5-b87e-38ee02143def    2453    OtherSRV-Designing Consultancy Fees     \N      f       \N      \N      f       \N
d2dddd96-e14c-4134-a916-3ab05f5d2f5a    2320    OtherSRV-Diesel \N      f       \N      \N      f       \N
a07c1630-f388-4ee9-a9ac-1c35ca164734    2313    OtherSRV-Etisalat One Time Charges      \N      f       \N      \N      f       \N
01986d62-6351-406a-8901-a48802f1f82f    2312    OtherSRV-Etisalat Other Credits and Charges     \N      f       \N      \N      f       \N
5864ce71-12e2-49ac-9a37-e1bfdb0b5cb7    2310    OtherSRV-Etisalat Service Rentals       \N      f       \N      \N      f       \N
3c419f2e-410d-4c56-bfed-2fe4bef82e27    2311    OtherSRV-Etisalat Usage Charges \N      f       \N      \N      f       \N
f338802c-2eff-4e24-a65b-31e55861db6c    132     OtherSRV-Events And Festival    \N      f       \N      \N      f       \N
52b9f422-0123-4323-8d01-58d2b05ce179    2452    OtherSRV-Firefighter Service    \N      f       \N      \N      f       \N
4b9fa211-db7b-49fd-bdda-35c177dbdb3e    142     OtherSRV-flowers For Branding   \N      f       \N      \N      f       \N
cf51deae-03ed-431a-af67-f2dee693f8b0    133     OtherSRV-Fuel Transportation Services   \N      f       \N      \N      f       \N
80be9014-9f94-4ede-8d3f-4f5f12f785c9    2091    OtherSRV-Government Fees        \N      f       \N      \N      f       \N
5db681b2-ee86-408a-926d-e68a6f6224fa    2088    OtherSRV-Hire and  Rentals - Decoration \N      f       \N      \N      f       \N
9b4b4b37-4cff-4f48-87d4-1602b37d85f1    2086    OtherSRV-Hire and  Rentals - Furniture  \N      f       \N      \N      f       \N
2ae9ed34-57d7-40cc-b25d-6e0e6f1515f2    2087    OtherSRV-Hire and  Rentals - Machinery  \N      f       \N      \N      f       \N
ca3fce08-5355-4f94-ac2d-2e3dddc25f37    2247    OtherSRV-Hire and Rentals - Audio & Video       \N      f       \N      \N      f       \N
39a22b1f-0660-4358-bd58-a40ec43dcea9    2223    OtherSRV-Hire and Rentals - IT Equipment        \N      f       \N      \N      f       \N
c9145d2b-6905-4010-82c6-a6393aba9e18    2246    OtherSRV-Hire and Rentals - lights      \N      f       \N      \N      f       \N
699ce677-6d31-498b-9b93-95ff2367f2a4    2386    OtherSRV-Hire and Rentals - Vehicles    \N      f       \N      \N      f       \N
ee7ffafb-6c05-4824-a903-85b2c79de629    2344    OtherSRV-Hire and Rentals -Washroom     \N      f       \N      \N      f       \N
c055ef85-4af7-472c-b075-b734a3129c90    130     OtherSRV-Hospitality And Reception Services     \N      f       \N      \N      f       \N
6efbe11d-b854-464a-8be6-33b7d7b03150    131     OtherSRV-Hospitality Services   \N      f       \N      \N      f       \N
c9860ab8-801e-4d77-be53-6dce871ca972    2125    OtherSRV-Immigration Charges    \N      f       \N      \N      f       \N
d35804c5-e972-4c37-b355-687c951ba2e2    2090    OtherSRV-Influencer     \N      f       \N      \N      f       \N
e39e509a-69aa-42b8-b6b0-fa1155d6b09b    128     OtherSRV-Laundry Service        \N      f       \N      \N      f       \N
642c1a46-791a-4da5-9d72-abdc5e1f56b2    2226    OtherSRV-Mawaqif Parking Fees   \N      f       \N      \N      f       \N
a9875b20-302b-47fd-9d8d-fe101b0cb342    2319    OtherSRV-Petrol special \N      f       \N      \N      f       \N
22fb2e52-6739-441a-8fe9-fd5b8c24fb83    137     OtherSRV-Real Estate Service    \N      f       \N      \N      f       \N
1342a798-0cd7-42a2-8406-431ece41c898    134     OtherSRV-Travel Services - Missions     \N      f       \N      \N      f       \N
5e745e95-0af4-4068-a09a-be29ba53ef34    2126    OtherSRV-Visa Medical Examination       \N      f       \N      \N      f       \N
04dc618f-9112-4471-8837-996dd16b83d8    2119    OtherSRV-Visa Typing Service    \N      f       \N      \N      f       \N
18930b17-687b-4110-ac21-444d1e67654d    2167    OtherSRV-⁠ Badge - ID Card      \N      f       \N      \N      f       \N
9251a764-309b-43b2-bff4-dcd0065b002e    2206    OtherSRV-⁠ Bank Charges \N      f       \N      \N      f       \N
b7926a14-e81c-498b-a614-9d62d4be6316    2166    OtherSRV-⁠ Banners      \N      f       \N      \N      f       \N
8aa32bbc-d00c-42e7-994e-9e1db1352d09    2113    OtherSRV-⁠ Delivery Charges     \N      f       \N      \N      f       \N
aa2e663f-1bc0-48b2-b959-5b54ccdce66b    2272    OtherSRV-⁠ Differensce In Currency Ex. And Converion Fees       \N      f       \N      \N      f       \N
73f6cefe-6f6f-4fb9-9c31-850fa8f4ad8d    2176    OtherSRV-⁠ Equine Dentistry Service     \N      f       \N      \N      f       \N
45c4ac09-1d73-4d30-bd82-6a73de03190f    2178    OtherSRV-⁠ Furniture Installation       \N      f       \N      \N      f       \N
9d99f562-947d-46ef-b412-db13ea2ef983    2170    OtherSRV-⁠ Horse Blood Testing and Tests        \N      f       \N      \N      f       \N
5de2e79e-c236-4c1e-8f99-4be6ba6426a2    2648    OtherSRV-⁠ MALL_ Leasing Management Fee \N      f       \N      \N      f       \N
627673c2-cfa6-4295-8796-1e0e7469dd88    2179    OtherSRV-⁠ Media Wall   \N      f       \N      \N      f       \N
0ee5ffd0-e980-4c7d-a315-d872f5915744    2112    OtherSRV-⁠ Promotional Gifts    \N      f       \N      \N      f       \N
2fc79410-3ce6-4ec3-b0f3-5bce1b07d2e6    2095    OtherSRV-⁠Commission On Purchase        \N      f       \N      \N      f       \N
7d5dd0f5-47b2-4835-9fc0-d62032f8004d    2225    OtherSRV-⁠Darb Toll Fees        \N      f       \N      \N      f       \N
cb424762-24b0-4205-b128-68c15b33c13d    2202    OtherSRV-⁠Freelance - Marketing \N      f       \N      \N      f       \N
40b35d2f-a9e6-4ef1-8a1e-171faa8a373a    2401    OtherSRV-⁠Freelance - Photographer      \N      f       \N      \N      f       \N
1c93f14b-656a-414d-91c4-0c3cb3108b83    2400    OtherSRV-⁠Freelance - POS Staff \N      f       \N      \N      f       \N
a32388fd-23bd-443a-874a-771d52405f2b    2647    OtherSRV-⁠Marketing - Live Streaming    \N      f       \N      \N      f       \N
374b1408-55c2-4682-adef-123d06f99d8d    2646    OtherSRV-⁠Marketing - Social Media Retainer     \N      f       \N      \N      f       \N
3829eae6-040d-484f-9123-3c2ca4305c26    2655    OtherSRV-⁠Marketing and Advertising Video production    \N      f       \N      \N      f       \N
76931cf0-f8df-40f9-9180-4bf14026ddaa    2114    OtherSRV-⁠Printing Services     \N      f       \N      \N      f       \N
1a40c43c-0bbb-4e84-a944-e635911f3d55    2118    OtherSRV-⁠Race Book printing Services   \N      f       \N      \N      f       \N
e1b3add4-0dd9-4f5c-8e05-c152edc1e367    2224    OtherSRV-⁠Salik Toll Fees       \N      f       \N      \N      f       \N
ada39bac-d8ab-48fd-b458-7ca4bedd6d79    2635    OutSource Riding School Trainer \N      f       \N      \N      f       \N
947fd154-8f49-4367-aa03-097e9bd6e9f1    2580    Paid Sponsorship        \N      f       \N      \N      f       \N
9ecb473c-5364-4b3a-b59c-44f6dedd65fa    146     Photography     \N      f       \N      \N      f       \N
7eb26acc-58c7-4bdc-8fac-0b8c9d2337eb    2085    PICKET FENCING  \N      f       \N      \N      f       \N
f0e3dcb7-fc06-4795-b69e-cd7da7be44b6    2464    Prizes _ Colorful Escape        \N      f       \N      \N      f       \N
a58a9e1f-01e9-4a01-b2c3-280b73de6050    144     Rental BARRIER  \N      f       \N      \N      f       \N
53cde928-5113-49d7-9657-a84e9efccfae    2264    Rental FENCING  \N      f       \N      \N      f       \N
ac82737b-0f81-4e1e-a0a3-64310a0fe3ed    2349    Pads (2)        300     f       \N      \N      f       0
003b83b4-401b-4c34-bcf5-e232ea1aef3e    2517    Safety Supplies \N      f       \N      \N      f       \N
3c8f5661-aa31-401a-b730-93e6fab9829f    2282    Sand Bags       \N      f       \N      \N      f       \N
6618beef-c9ea-466c-9834-56a766a08156    122     Services - Subscriptions        \N      f       \N      \N      f       \N
2dd23249-4531-4cca-9599-9b73eada93c6    2111    Signages        \N      f       \N      \N      f       \N
2c40f14f-6952-4e94-bc26-45d646dd9274    2632    SRV-Best Dressed Competition Awards     \N      f       \N      \N      f       \N
d8517429-1402-4da0-b586-825fe29cb409    145     Staff Clothing  \N      f       \N      \N      f       \N
ffcecf90-cc8e-4b1d-94b1-f7c0353e3891    683     StationaryMAT -A4 ICE GOLD PAPER 300 GSM        \N      f       \N      \N      f       \N
48c23928-db25-40f2-b07b-d490dd4a9f18    681     StationaryMAT -ADEC Enrollment Application Folder       \N      f       \N      \N      f       \N
bd30daae-e6f0-49a9-953d-18c2868304d2    682     StationaryMAT -ADEC Notebook A5 \N      f       \N      \N      f       \N
332693e5-6edc-4f61-9304-314637d29499    2666    StationaryMAT -Brother TONER,  TN - 2125        \N      f       \N      \N      f       \N
3fe537aa-82b3-4b1a-8a7c-2273571f3823    618     StationaryMAT -Date Stamp       \N      f       \N      \N      f       \N
107611bc-dbcd-425e-9ecf-ad5d458c6178    564     StationaryMAT -ENROLLMENT APPLICATION FORM A3/A4 1000'S \N      f       \N      \N      f       \N
997fcee3-efa2-4c2d-9f84-dfb5ecf931ce    581     StationaryMAT -INDEX PAPER A4 DEVIDER   \N      f       \N      \N      f       \N
f6478859-36c5-4498-87c1-317adbbaef9a    663     StationaryMAT -KEY BOX 400 KEYS \N      f       \N      \N      f       \N
0585b74e-5d29-4662-9cbb-3b20fac4062c    536     StationaryMAT -LETTER PAD       \N      f       \N      \N      f       \N
10068fa9-51f8-43c4-b7ba-9408cf62e17f    544     StationaryMAT -PLASTIC DIVIDER  \N      f       \N      \N      f       \N
a9085382-1115-4c00-acd5-29ebe4af8649    2618    StationaryMAT -PVC Foldable Clip Board A4       \N      f       \N      \N      f       \N
926ac45e-1887-411a-a359-8c40f7e151d5    580     StationaryMAT -SAFETY PIN       \N      f       \N      \N      f       \N
4239147b-90e2-465c-a9d6-a0f3837841c7    550     StationaryMAT -SIGNATURE FILE   \N      f       \N      \N      f       \N
4c314455-8f61-4be2-86e2-b1d3b2681073    569     StationaryMAT -STAPLER PIN AMEST NO. 65 \N      f       \N      \N      f       \N
2eb7c320-95f0-4f74-8224-47888c1ae730    2678    SubscriptionsSRV-  HR Software Monthly  \N      f       \N      \N      f       \N
ab06aa59-b6be-494a-a19e-494704dcf11f    123     SubscriptionsSRV- ## Renewing Licenses  \N      f       \N      \N      f       \N
ccf67144-79d3-4f81-8117-2e712c992114    125     SubscriptionsSRV- ##Consultancy and Technical advice    \N      f       \N      \N      f       \N
b3666242-7a69-465a-87f8-ae31a301caca    2644    SubscriptionsSRV-Federation Calendar Fee        \N      f       \N      \N      f       \N
577cf3ff-cf5b-4142-b68d-d2d36e8ae47b    2645    SubscriptionsSRV-Federation Organization Fee    \N      f       \N      \N      f       \N
3541a5b9-ca91-40ef-ba35-b888dcc5c52c    124     SubscriptionsSRV-Medical Insurance      \N      f       \N      \N      f       \N
b099b486-8538-4122-b5bf-c8e651991d30    126     SubscriptionsSRV-Various Service        \N      f       \N      \N      f       \N
5ceaf474-1e09-4a24-b9ee-2d4a502d4ae7    2093    SubscriptionsSRV-Vehicles Insurance     \N      f       \N      \N      f       \N
07cbda55-5d5b-4eba-baf8-3924c2347308    1530    TackMAT -ACTIMOVED MASSAGE MACHINE      \N      f       \N      \N      f       \N
0dac6e2f-4645-4ab5-985f-24e31689325f    1440    TackMAT -ALUMINIUM RASP HANDLE  \N      f       \N      \N      f       \N
1e8821e9-f3d1-48e0-a038-eb55c6412957    1575    TackMAT -AMBERSIL SILICONE OIL – 1LTR   \N      f       \N      \N      f       \N
d3c9e269-c8ad-4df7-8c3d-5c0e5669195d    1591    TackMAT -AUTOMATIC WATER DRINKER        \N      f       \N      \N      f       \N
34a72c80-a07e-4246-ab5c-bbc26498f3ef    1586    TackMAT -BLUE SNOW SHAMPOO – 500ml      \N      f       \N      \N      f       \N
e0074970-8833-4565-9830-7a62137887e0    1447    TackMAT -BODY PROTECTOR \N      f       \N      \N      f       \N
68fdf170-beb0-461a-bfc0-936b9ec891a7    1449    TackMAT -BOOT PULL      \N      f       \N      \N      f       \N
b73bcf2a-e65e-41ca-a774-db0764cd49bc    1454    TackMAT -CHIFTNEY BIT WITH STRAP        \N      f       \N      \N      f       \N
d24c869f-f5e7-426e-aec9-2aed17eaaab3    1457    TackMAT -CONTINENTAL WEB REINS  \N      f       \N      \N      f       \N
0c4dea18-5592-4aff-9820-d0f3f3b53654    1337    TackMAT -CUP & SAUCER 1X12      \N      f       \N      \N      f       \N
3b0fbdd1-fe46-4e1b-a5b9-df08510d0c63    1460    TackMAT -D RING BIT WITH ROLLER \N      f       \N      \N      f       \N
0459ad10-df7c-4134-945d-03c4940f10ff    1465    TackMAT -EFFOL SHAMPOO - 5LTR.  \N      f       \N      \N      f       \N
ac003c0f-4abc-4bd0-bdff-d5944f8059fa    1573    TackMAT -ENDURANCE BREECHES     \N      f       \N      \N      f       \N
1ce8065d-5fc5-4e16-9ce8-7ea476a48675    1468    TackMAT -EQUIP HORSE BRIDLE SET \N      f       \N      \N      f       \N
c8542324-eaf6-4d15-a39a-c8f4deda2569    1570    TackMAT -FACE MASK      \N      f       \N      \N      f       \N
a2dbee5e-3090-4023-8318-6b7dcd686d2a    1552    TackMAT -FETLOCK SCISSORS       \N      f       \N      \N      f       \N
eea1f20d-d918-410e-b70a-1b47f0103160    1551    TackMAT -FLEECE GIRTH   \N      f       \N      \N      f       \N
2e859ae1-a320-4c7a-817b-c72a9edd50d5    1565    TackMAT -FLY ATTRACTANT \N      f       \N      \N      f       \N
c19e664e-280b-478b-b605-af08a93f3dda    1581    TackMAT -FLYSHEET BLANKET       \N      f       \N      \N      f       \N
e8e09f17-bfcf-44a7-b344-1bcdb1ed4f6c    1577    TackMAT -GAG CHEEK BIT  \N      f       \N      \N      f       \N
0bf0ff80-e381-4e6b-a078-3bfe1508a3cd    1571    TackMAT -GARMIN – GPS   \N      f       \N      \N      f       \N
9e209c72-5062-4fc2-a219-f96ad1b9a948    1350    TackMAT -GEL PAD        \N      f       \N      \N      f       \N
f8a0d259-5bb1-4e29-af82-e11f66b8a5d5    1351    TackMAT -GIRTH SLEEVES  \N      f       \N      \N      f       \N
c0813509-8171-4df0-a2c6-63bee15ed6bf    1329    TackMAT -GLOBE TROPHY   \N      f       \N      \N      f       \N
629c33ac-839a-48a2-82f5-1bb47f5ee173    1330    TackMAT -GOLD PLATE TROPHY      \N      f       \N      \N      f       \N
46da3cd6-fa73-493a-aef3-37a1febcb22e    1464    TackMAT -HA 300 DRENCHING GUN 300CC WITH NOZZLE \N      f       \N      \N      f       \N
aa654999-3441-41a2-af8f-57022a93fc91    1576    TackMAT -HACKMORE BIT STAINLESS STEEL WITH PVC NOSE     \N      f       \N      \N      f       \N
1dc5506a-7fde-4e58-bb6b-6c11c888e181    1361    TackMAT -HAMPA VORDERBEINE LEATHER BOOT \N      f       \N      \N      f       \N
58723839-ced3-4ff9-b517-fb90819e14ac    1363    TackMAT -HEAD COLLAR ROPE       \N      f       \N      \N      f       \N
8f42558e-4415-4510-89e2-b6b65b583733    1364    TackMAT -HEART CHECK    \N      f       \N      \N      f       \N
a0c2f8a0-7b8f-4222-8d99-1a71e2a4102b    1560    TackMAT -HENNA  \N      f       \N      \N      f       \N
edcb57f2-9bbb-4b32-8b78-d0993d92fb68    1346    TackMAT -FLY MASK       \N      f       \N      35.97   f       35.97
d1d14f0e-d464-4a66-8ac1-35156055aed0    1587    TackMAT -HOOF TAR- 1Ltr - Tittini       \N      f       \N      \N      f       \N
ec693473-ac79-471c-bb72-1e6c19b02d3d    1580    TackMAT -HORSE BLANKET - INTERNATIONAL SHOWJUMPING      \N      f       \N      \N      f       \N
604c4167-bd5a-4310-9f9e-75f8559d7c23    1367    TackMAT -HORSE BLANKET WITH LOGO        \N      f       \N      \N      f       \N
12f7e754-a64e-4ef0-8573-5c243c7956ca    1540    TackMAT -HORSE FLY BLANKET (NET TYPE)   \N      f       \N      \N      f       \N
74b5a96c-1f2d-4337-8cba-7fa924b62c7f    1584    TackMAT -HORSE SHINING SPRAY 1 LTR      \N      f       \N      \N      f       \N
4c33c4c9-25a5-43b5-996b-6995efe039af    1557    TackMAT -ICE-O-POULTICE --HAWTHORNE     \N      f       \N      \N      f       \N
133b6553-8bf4-415c-9e7d-d1cbd8e6c320    1566    TackMAT -ICE-O-POULTICE 22.6 KG \N      f       \N      \N      f       \N
73acadf0-f2e9-4328-820e-69f64c5c598c    1562    TackMAT -JOCKEY WEIGHT PAD 8 KG \N      f       \N      \N      f       \N
c418d14e-637f-4860-be33-56cf23b27627    1568    TackMAT -LASER SHEEN 32OZ       \N      f       \N      \N      f       \N
616817d6-0535-43d5-a634-5ad7025f250b    1374    TackMAT -LEATHER BRIDLE \N      f       \N      \N      f       \N
7bc5f9be-ea3e-4295-aeef-746226157e7b    1375    TackMAT -LEATHER DRESSING - GAL \N      f       \N      \N      f       \N
208726d6-7788-4aeb-9b00-a5288b1f45e5    1547    TackMAT -LEATHER GIRTH  \N      f       \N      \N      f       \N
4f62f961-85da-42ee-95fa-213422f2205c    1601    TackMAT -LEATHER GREASE 500Gm   \N      f       \N      \N      f       \N
79c1da9e-a891-4b3d-9fd0-897db3d51922    1377    TackMAT -LEATHER HEAD COLLAR-   \N      f       \N      \N      f       \N
f8c08703-b2e1-4656-8595-1039f904fc54    1378    TackMAT -LEATHER HEAD COLLAR-PONY       \N      f       \N      \N      f       \N
14e2125c-38a8-4d2a-a2c1-9ca28ffee284    1383    TackMAT -LEATHER PONY SADDLE    \N      f       \N      \N      f       \N
ca32cbd6-80ec-4673-90f1-11ca0aa852aa    1546    TackMAT -LEATHER PUNCHER MACHINE        \N      f       \N      \N      f       \N
85d00796-a2e5-4b0b-aa9d-7d5823ef2764    1384    TackMAT -LEATHER STIRRUP STRAP- 145 CM  \N      f       \N      \N      f       \N
b4964078-4b87-468e-80bb-4fbb270ae2d4    1386    TackMAT -LEG WRAPS - PAIR       \N      f       \N      \N      f       \N
fbd6ec32-6f04-47cf-97c3-0dec7f97f464    1602    TackMAT -MAN O WAR SHAMPOO - GAL.       \N      f       \N      \N      f       \N
bccce9dd-e700-4ef5-b8b1-531f94745c91    1387    TackMAT -MENS BREECHES EQUILINE \N      f       \N      \N      f       \N
805dc51e-839a-47f0-a516-32010e2b6a9d    1388    TackMAT -METAL SWEAT SCRAPER    \N      f       \N      \N      f       \N
0e55c0a3-0c32-4c9b-885c-4e7832c85e26    1391    TackMAT -NECK CRADLE    \N      f       \N      \N      f       \N
a3510759-7e72-4c87-ad3a-a6032aa16593    1585    TackMAT -NEODERMA SHAMPOO – 500ml       \N      f       \N      \N      f       \N
6ebd51c2-3626-4c77-8536-0b598d2fd280    1550    TackMAT -NEOPRENE CHAPS \N      f       \N      \N      f       \N
b2859f94-1a46-4756-b38f-4808c68cbe4e    1392    TackMAT -NINE POCKET ICE BOOTS  \N      f       \N      \N      f       \N
6b269973-b29b-4432-805b-bac1d1d09cfa    1597    TackMAT -NOSE FILL DRINK BOWL – WALL FIX (DBL5) \N      f       \N      \N      f       \N
95de2df6-01c9-4be7-9479-601da60344d0    1393    TackMAT -NYLON BRIDLE   \N      f       \N      \N      f       \N
2578d6e9-525d-4386-8aab-acc7befc6bc0    1395    TackMAT -NYLON HEAD COLLAR-FULL SIZE    \N      f       \N      \N      f       \N
d3eed8c9-74ef-4304-90fe-2b4fff051cca    1398    TackMAT -NYLON LEAD ROPE        \N      f       \N      \N      f       \N
a694f072-698c-4721-aa1b-7481b7edecd2    1598    TackMAT -Oster Clipper Blade # 40       \N      f       \N      \N      f       \N
0b63be97-c025-4ac7-bde1-fcfcf2ea8a8b    1599    TackMAT -Oster Clipper Blade # 50       \N      f       \N      \N      f       \N
f4b74a07-bdba-4fe9-8345-021f7614595c    1527    TackMAT -PLASTIC FEED SCOOP     \N      f       \N      \N      f       \N
59edc6f2-6237-4bce-8f84-a40175b9f4ba    1554    TackMAT -POLAR EQUINE RC3 GPS   \N      f       \N      \N      f       \N
b5ba2b75-b889-4280-b8c5-0562f11d7c3f    1534    TackMAT -RACE BAT       \N      f       \N      \N      f       \N
9ce72fbf-19a9-407d-b45d-f37a4b151379    1415    TackMAT -RACE BLINKERS  \N      f       \N      \N      f       \N
f921e0fb-52a0-4835-a83e-aeac17f3d972    1416    TackMAT -RED CELL = GALON       \N      f       \N      \N      f       \N
d89186fe-3a4f-4975-8903-e52a533d1198    1418    TackMAT -REGENT BOOT    \N      f       \N      \N      f       \N
fa6e1eaf-0bf9-4aa5-bf3d-892e9d4695fc    1494    TackMAT -RIDING BOOT    \N      f       \N      \N      f       \N
64c54d01-9bd8-493d-88b8-d12f6cf7d18b    1495    TackMAT -RIDING BOOT LEATHER    \N      f       \N      \N      f       \N
3e8bd917-c666-4010-8b07-11a5d6625c62    1569    TackMAT -RIDING BOOT – CHESTER  \N      f       \N      \N      f       \N
04bf15cd-9f6b-40c6-99c0-ab6bc5346659    1502    TackMAT -RIDING BREECHES        \N      f       \N      \N      f       \N
17da44bc-9cca-4adc-ac1c-5dd42129d3ff    1578    TackMAT -ROPE GAG CHEELS WITH BUCKLE    \N      f       \N      \N      f       \N
b576af13-4381-4486-8106-4a61fd7f10cf    1420    TackMAT -ROSSETES REPAIR NO. 1-8 (80 EACH X 8)  \N      f       \N      \N      f       \N
e18f7953-6d38-46e5-8006-5af5f1eb55dd    1421    TackMAT -RUBBER BELL BOOTS      \N      f       \N      \N      f       \N
226523e6-065e-4e8d-ae60-aba65072d396    1594    TackMAT -RUBBER BELL BOOTS BLACK COLOR  \N      f       \N      \N      f       \N
5e64d61b-84f8-47e2-8b92-b58911d6927d    1424    TackMAT -RUBBER GRIP REINS      \N      f       \N      \N      f       \N
1fbcfd5b-961f-4059-826b-d24ed4e6eb4e    1425    TackMAT -RUBBER REIN STOPS      \N      f       \N      \N      f       \N
0dd0fb87-b203-4bf7-8724-07c4b15760c5    1426    TackMAT -RUNNING MARTINGLE      \N      f       \N      \N      f       \N
5d5b9932-ace8-481a-81b2-fa2144e14f9b    1427    TackMAT -SADDLE BROCCO NORTHERN POLEY   \N      f       \N      \N      f       \N
5a8b3744-03f2-4714-808f-9a0f975531df    1497    TackMAT -SADDLE PAD     \N      f       \N      \N      f       \N
c2a29f04-b466-4ff9-aaca-24ffb76f1f65    1548    TackMAT -SADDLE PAD HORSE GRAY COLOR    \N      f       \N      \N      f       \N
1d91e582-2890-4d0a-89e1-0a40ddfffa07    1600    TackMAT -SADDLE RACK FOLDING TYPE       \N      f       \N      \N      f       \N
811ab7eb-37f1-48ad-b0e2-c9c198894b26    1572    TackMAT -SADDLE – GASTON MERCIER        \N      f       \N      \N      f       \N
4cd47fc6-8c5a-4e39-8d10-33705c18afa7    1430    TackMAT -SAFETY BOOT    \N      f       \N      \N      f       \N
55f6b88c-38e2-4c79-8a2d-842944a1176c    1431    TackMAT -SAFTEY TIE STRAP       \N      f       \N      \N      f       \N
3a06fe89-838f-4f77-940f-f9f7a49f5f17    1432    TackMAT -SAFTY SHOES    \N      f       \N      \N      f       \N
3f6c22d8-03aa-4051-9790-e101a38357a1    1434    TackMAT -SATIN SHEEN-QRT        \N      f       \N      \N      f       \N
c9393aef-4ef8-474f-9489-537d9ddedbd1    1564    TackMAT -SCISSOR FOR HORSE HAIR CUT     \N      f       \N      \N      f       \N
3f26e8a3-f6b6-4f38-bb6b-3df2d7d9970a    1595    TackMAT -SEAT SAVE GEL PAD TRANSPARENT  \N      f       \N      \N      f       \N
f822ad6e-0621-490c-8203-d234ca25054f    1549    TackMAT -SHOWEL \N      f       \N      \N      f       \N
77b49df9-455a-49f3-a60f-e5ce66bea299    1469    TackMAT -SOLID WEB LUNGE REINS  \N      f       \N      \N      f       \N
b0390c8f-f233-47a4-8fb1-945c7214697c    1596    TackMAT -STABLE MATE WITH SCOOP BEUCEPHAL       \N      f       \N      \N      f       \N
501ae2b6-a790-45fa-99db-43d0cca46112    1477    TackMAT -STAR BRIDLE    \N      f       \N      \N      f       \N
05357e7f-876d-49a8-9020-2100da05fa7b    1479    TackMAT -STIRRUP IRON BLACK COATED-PAIR \N      f       \N      \N      f       \N
958d396d-01a4-4b62-ba16-487e55955119    1531    TackMAT -STIRRUP IRON FOLTY     \N      f       \N      \N      f       \N
ecc14c50-6b85-4cef-9089-5bc5552cf5ed    1480    TackMAT -STIRRUP KEY RING       \N      f       \N      \N      f       \N
7028303c-c543-45f3-9772-29da351c2bc4    1481    TackMAT -STIRRUP LEATHER        \N      f       \N      \N      f       \N
126d931e-50b6-48b6-9a47-f5165f060930    1482    TackMAT -STUD GUARD GIRTH       \N      f       \N      \N      f       \N
9ef079d5-638f-418a-a6cf-f8d776d1ac3d    1567    TackMAT -SUPER IODINE SHAMPOO – QRT     \N      f       \N      \N      f       \N
846e3d5b-23f9-4878-b939-b30aad0262e4    1593    TackMAT -TENDON BOOTS BEUCEPHAL (FRONT & BACK)  \N      f       \N      \N      f       \N
531ae5ef-ad18-49f2-bd92-2661bdd3f5f8    1486    TackMAT -THOROWGOOD SADDLE      \N      f       \N      \N      f       \N
f893f796-5773-4c27-9300-30559d47a307    1489    TackMAT -VALET CURRY COMB       \N      f       \N      \N      f       \N
f3e7bd64-fa5c-4738-b0d9-fff8d69c70b4    1490    TackMAT -WALHEUSEN GIRTH        \N      f       \N      \N      f       \N
aa65ecb6-4318-4a0e-9982-c79aefe71011    1506    TackMAT -WATER BRUSH    \N      f       \N      \N      f       \N
be31d094-8fa1-4e3b-8cbb-162f0c97bd45    1491    TackMAT -WINTEC ELASTIC GIRTH   \N      f       \N      \N      f       \N
7d84a274-524c-47c9-917b-c341fee61dd6    1492    TackMAT -WINTEC GIRTH   \N      f       \N      \N      f       \N
ad01c91d-862a-4a81-991c-e3c42db27e82    2280    Translation Service     \N      f       \N      \N      f       \N
c9b83140-3175-4b97-b179-3630be951476    2300    UniformnMAT - Events Black Polo T-Shirt with logo 2025  \N      f       \N      \N      f       \N
6aa2af06-703a-417a-b6f5-435e192687bc    2301    UniformnMAT - Green Hoodies with logo 2025      \N      f       \N      \N      f       \N
b06413c9-fe04-45d9-9528-8d7294f70fd9    120     Water  - TAQA   \N      f       \N      \N      f       \N
652cb9cd-c954-495d-822f-04d1cb62a0b5    2228    Winner Horse Blanket    \N      f       \N      \N      f       \N
af77679d-0701-4691-b3f4-4fb6cec1bf03    2461    Wrapping item   \N      f       \N      \N      f       \N
79e2cc94-87b9-45be-9993-63fe4b8ef2f2    2098    ⁠OtherSRV-⁠Freelance - Branding \N      f       \N      \N      f       \N
d177f1ae-455e-4767-b1e0-660b943b37ab    2846    CleanMAT -FINE TOILET TISSUE ROLL 1X90 350SHEETS 2PLY   \N      f       \N      \N      f       \N
40dea280-6150-4f27-b494-5155f23bb92b    2722    Collection Charges - Platinum List Equipment Charges    \N      f       \N      \N      f       \N
c23392ec-5766-4b69-b2bd-8e48c0e13241    2723    Collection Charges - Platinum List – Management Fee     \N      f       \N      \N      f       \N
38f2d38e-57de-4b67-a1d8-b03d0cc11152    2721    Collection Charges - Platinum List – Staff Charges      \N      f       \N      \N      f       \N
b0993482-b848-4625-8917-84f89484e2f6    2724    Collection Charges - Platinum list – Technical Support Fee      \N      f       \N      \N      f       \N
0bce7002-e2f5-4384-b67a-b5dfddb29612    2720    Collection Charges - Platinum List – Ticket Printing Charges    \N      f       \N      \N      f       \N
96290d68-c1b1-401e-b693-ec17dd751ef1    2719    Collection Charges - Platinum List – Ticket Service Charge      \N      f       \N      \N      f       \N
5407241b-ce32-49cc-808c-d39e0cd3488c    2761    ConsultancySRV- Legal Consultancy Service       \N      f       \N      \N      f       \N
ee1e0316-2cb1-4580-9311-638604c25526    2691    ConsultancySRV- Recruitment Fees        \N      f       \N      \N      f       \N
143aa167-e888-47c5-821a-893c3e1084e6    2726    ConsultancySRV- Showjumping Arena Consultancy   \N      f       \N      \N      f       \N
ca2125ac-e254-43b1-97db-5d8353eec836    2692    Drinking Water  \N      f       \N      \N      f       \N
148b25c0-02fd-4463-94d5-164ed5ab2d9b    2736    EquestiranMAT -Metal Die Cut Trophy 25cm        \N      f       \N      \N      f       \N
72bef8ef-b004-42c3-ab8a-cba88c24f578    2725    Event Specialized operators - Carousel  \N      f       \N      \N      f       \N
46a22b36-6830-4a7d-8725-0298288e699e    2767    Events Trophies & Presentations \N      f       \N      \N      f       \N
8128b96d-a5cb-4e5b-8f3d-13760d0fc1eb    2730    EventSRV- Temporary Structure Fabrications      \N      f       \N      \N      f       \N
9e2b36b1-d0e9-4137-a633-813b6edf4ef2    2827    HorseFoodMAT -Oaten Hay 30kg/bale       \N      f       \N      \N      f       \N
6fa45419-9016-4a51-a7ad-5878eadf7422    2762    Al Wathba – Sponsorship (Unbilled)      \N      f       \N      \N      f       0
0be68973-85f9-4a34-9896-e8ac05d835e3    2748    MaintenanceSRV- Electrical scooter      \N      f       \N      \N      f       \N
699aa0c5-ef3f-4c08-b93d-0b0f5c706011    2747    MaintenanceSRV- Golf club car   \N      f       \N      \N      f       \N
c2c7a37c-94ea-491e-b243-071332fbb3a4    2681    MaintenanceSRV- Grass Track and Sandtrack       \N      f       \N      \N      f       \N
b24656be-72b1-4117-9f92-69af0f06dc29    2753    MaintenanceSRV- Irrigation Maintenance Works    \N      f       \N      \N      f       \N
a2a33936-19f6-41c9-8eb9-a6d8ca1e6ce8    2680    MaintenanceSRV- Manual Irrigation       \N      f       \N      \N      f       \N
544bc1d4-1ef3-4373-a8e5-7952a5d7fa54    2729    MaintenanceSRV-ADEC Landscaping & Irrigations  - AMC Services   \N      f       \N      \N      f       \N
f58e648b-ecc0-48db-9137-101291d94b5f    2728    MaintenanceSRV-ADEC TFM- AMC Services   \N      f       \N      \N      f       \N
59c20c00-3e82-41dd-b4b7-bc227e39e3e3    2783    MaintenanceSRV-Arcades + SJGS TFM- AMC Services \N      f       \N      \N      f       \N
aa459c64-f16d-4873-ae42-ebb5e1fd9791    2829    MaintenanceSRV-Civil Works      \N      f       \N      \N      f       \N
86d8a056-4b1c-4ea8-af38-e73a94b0b623    2714    MaintenanceSRV-Landscaping & Irrigation - Monthly       \N      f       \N      \N      f       \N
5e063bbd-6b9e-4ed4-a370-f7e6fa81fd72    2739    MaintenanceSRV-Landscaping Others       \N      f       \N      \N      f       \N
15c49e46-e18a-40be-9073-dd78d24b5d38    2830    MaintenanceSRV-MEP Works        \N      f       \N      \N      f       \N
079d4f91-0c82-4add-bd21-ae77ee452b4c    2689    MaintenanceSRV-Showjumping Poles painting & Repair      \N      f       \N      \N      f       \N
3630ff6d-c720-4603-ae41-039ea37084b0    2825    OtherSRV- Donation to Make a Wish       \N      f       \N      \N      f       \N
1efd1f15-5837-42ca-99a1-6e51c10a3351    2750    OtherSRV-Cleaning - Waste Water Tanker  \N      f       \N      \N      f       \N
a6d43fe7-64f1-4d13-93a3-de035db32748    2738    OtherSRV-Cleaning Medical waste removal charges \N      f       \N      \N      f       \N
d8afc77f-a899-4962-bbb4-8095f77856e3    2765    OtherSRV-Financial Consultancy Fees     \N      f       \N      \N      f       \N
29f7365e-b617-49cc-8001-e64579d3cc19    2710    OtherSRV-Hire and Rentals -Water Tanks  \N      f       \N      \N      f       \N
135ee297-85a7-4295-826b-71510ac8daba    2698    OtherSRV-Mall Retainer Fee      \N      f       \N      \N      f       \N
db2527ed-d4de-464f-a61d-56c727c89ddf    2784    OtherSRV-Perfume for Aroma Diffuser     \N      f       \N      \N      f       \N
9d990c16-30f3-4eac-9ce1-4d9b970fff90    2697    OtherSRV-⁠Agency Fee- Marketing \N      f       \N      \N      f       \N
387d7fe2-fcb2-4c6b-aeca-8540c0aa179a    2696    OtherSRV-⁠Digital Campaign Charges- Marketing   \N      f       \N      \N      f       \N
87f95659-becc-4c2b-ac04-0cf49e423f10    2727    OtherSRV-⁠Marketing - Media Evaluation  \N      f       \N      \N      f       \N
cf33dd02-cfaa-418b-b153-abdf5eb9e8af    2737    OtherSRV-⁠Marketing - PR &Communications        \N      f       \N      \N      f       \N
05a32956-1509-49f1-9371-0db3c75ddd87    2755    Recycled Water  - TAQA  \N      f       \N      \N      f       \N
09872669-43d6-4e2b-8710-47715cf5976d    2744    Services - Adobe.com subscription – (Marketing )        \N      f       \N      \N      f       \N
358afc19-32a1-4d52-bf92-93f4b7859022    2746    Services - BITLY.COM subscription ( Digital Transformation)     \N      f       \N      \N      f       \N
5fbbc93c-0fac-428e-9734-1e20d8330613    2740    Services - Figma subscription (Digital Transformation)  \N      f       \N      \N      f       \N
cbc67b67-d5c4-4e34-a8c0-4c7ab923b609    2745    Services - LinkedIn subscription (HR )  \N      f       \N      \N      f       \N
8545c1aa-0320-4a6c-868c-23133ea33187    2742    Services - Mailchimp subscription (Marketing)   \N      f       \N      \N      f       \N
1f90f054-64e7-4760-9d8f-64b5a1d437af    2751    Services - MAll_  Contract Registration \N      f       \N      \N      f       \N
1ae1f7de-2632-4f3a-8fca-ddfbb85a19f8    2752    Services - MAll_ Contract typing        \N      f       \N      \N      f       \N
da863568-1f98-4473-a2df-4ba2861eee08    2741    Services - PERPLEXITY.AI subscription (Digital Transformation ) \N      f       \N      \N      f       \N
5931e790-db18-452b-8ec6-57d60857e8af    2743    Services - SHUTTERSTOCK subscription ( Marketing )      \N      f       \N      \N      f       \N
28b80487-5a67-4293-81ba-647d7d16a432    2713    Services - Subscriptions - EzyVet monthly Subscription  \N      f       \N      \N      f       \N
320a1004-f0a1-4b8f-a38e-d1e5d6f5d1a6    2733    StaffOtherAllowances - Fazza- Gold Membership – Annual  \N      f       \N      \N      f       \N
5510796e-40f9-47aa-b26d-09eb92c943e3    2732    StaffOtherAllowances - Fazza- Platinum Membership – Annual      \N      f       \N      \N      f       \N
8f9d9a63-2e66-4537-a12e-508981e605d2    2734    StaffOtherAllowances - Fazza- Silver Membership – Annual        \N      f       \N      \N      f       \N
6c1ac3e7-ea62-4f79-bfb9-e5c548060723    2858    StationaryMAT -SANDISK FLASH DRIVE 32GB \N      f       \N      \N      f       31
55257b1a-ab56-4917-b31e-ca38d92433c0    2857    StationaryMAT -SANDISK FLASH DRIVE 64GB \N      f       \N      \N      f       37
8dc6a0e4-e3b1-4dc7-813e-503691af369f    2824    StationaryMAT -SANDISK FLASH DRIVE 16GB \N      f       \N      \N      f       \N
8be4c2d9-64a5-4c4e-a023-1f1be848d344    2683    SubscriptionsSRV - Race Consultant      \N      f       \N      \N      f       \N
37f96585-0cef-4bf7-9388-d3a04eaec573    2716    SubscriptionsSRV DT -Microsoft Visio Plan 2 License Renewal     \N      f       \N      \N      f       \N
72522e91-508b-4e8b-86b8-ceffd4880a11    2685    SubscriptionsSRV IT -Microsoft Office 365 Exchange      \N      f       \N      \N      f       \N
d37eea0d-c6b5-4a6f-b60c-72b2b49d6efe    2679    SubscriptionsSRV-  Project Management Fee       \N      f       \N      \N      f       \N
4df62f04-efe3-4a7b-9dd5-80062301c77f    2688    SubscriptionsSRV- ESPIRE Livery Management System       \N      f       \N      \N      f       \N
24a8fb09-b2bf-4b03-81f2-5a49456242c9    2754    SubscriptionsSRV- ESPIRE – TIMS ERP system charges      \N      f       \N      \N      f       \N
90d72c76-2986-48c4-9b72-5ea0682720ef    2682    SubscriptionsSRV- Oracle Renewing Licenses - Quarterly  \N      f       \N      \N      f       \N
a5618473-c944-430a-a091-e1091162376e    2690    SubscriptionsSRV-Figma subscription     \N      f       \N      \N      f       \N
67e55113-3be2-4b2b-8640-f1f209ddea0a    2684    SubscriptionsSRV-Microsoft Office 365 Premium   \N      f       \N      \N      f       \N
dc210d91-dd2b-4f00-b0a0-07ac90562827    2686    SubscriptionsSRV-SharePoint File Storage        \N      f       \N      \N      f       \N
11c5ddef-2c0e-484b-b4f7-fd8402aa6567    2802    UniformnMAT -Executive pants Male,Female-Receptionist   \N      f       \N      \N      f       \N
58596b3b-eb34-4d9b-b779-3089412af8a1    2799    UniformnMAT -Executive pants-OFFICE BOY \N      f       \N      \N      f       \N
fc72be5a-8286-44c2-8ffd-fdc9a090aa76    2800    UniformnMAT -Male,Female shirt-Receptionist     \N      f       \N      \N      f       \N
55be7955-3de9-4805-8cf6-818007a70569    2801    UniformnMAT -Male,Female vest jacket with logo-Receptionist     \N      f       \N      \N      f       \N
e503be60-0ac1-4dc6-830f-79aa15f3c293    2795    UniformnMAT -Polo T-shirt with logo, BLACK-SECURITY     \N      f       \N      \N      f       \N
3e1dbcd9-69ea-4fcb-baca-b0ad47ad0018    2791    UniformnMAT -Polo T-shirt with logo-FARRIER     \N      f       \N      \N      f       \N
541cb2fa-8052-4a2d-8a33-1f4daef0e8b7    2798    UniformnMAT -Polo T-shirt with logo-OFFICE BOY  \N      f       \N      \N      f       \N
10227bf2-46be-4140-b012-8a6a37122b92    2749    Water - Sweet Water Tanker      \N      f       \N      \N      f       \N
3b6f998e-205b-4790-907c-d1dbdff8ac4d    2856    StationaryMAT -A4 Envelope ADEC Natural White (Landscape)       \N      f       \N      \N      f       3.875
\.


--
-- Data for Name: livery_agreements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.livery_agreements (id, reference_number, customer_id, box_id, item_id, start_date, end_date, type, status, notes, checkout_reason, monthly_amount, agreement_category) FROM stdin;
eb1f2054-37c1-4c9a-8b27-7421ae3dd6cb    LA-2026-2949    8cd719bb-46a3-463c-be83-24ae1928f357    7282059a-1968-4468-9ed3-b20526f10ee7    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-11-15      \N      permanent       active  \N      \N      4500    with_horse
976428ba-6eaa-483c-b01d-1d0fb91f0955    LA-2026-5938    96372285-ae9a-45bb-acbf-95d3447b87bb    2d9bf537-4771-4e91-ad5f-c67e9178d69c    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-11-01      \N      permanent       active  \N      \N      2500    without_horse
e8e4adb3-7be3-435d-8d94-15c157586e38    LA-2026-7920    96372285-ae9a-45bb-acbf-95d3447b87bb    f231df6c-a72f-433a-b5ca-a88981152eee    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-11-01      \N      permanent       active  \N      \N      2500    without_horse
78f872d8-f649-42a0-9bfa-e2170cfeabab    LA-2026-9735    96372285-ae9a-45bb-acbf-95d3447b87bb    1a74eb4c-4815-4721-824d-4d0443fe307e    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-11-01      \N      permanent       active  \N      \N      2500    without_horse
c697f17b-cdef-47e5-b0cb-9cd9ed1a3ba0    LA-2026-6641    96372285-ae9a-45bb-acbf-95d3447b87bb    728c2e50-8cfb-4748-bc40-b5e9964c4d1e    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-11-01      \N      permanent       active  \N      \N      2500    without_horse
275d4902-18fc-408f-ba3b-1919ee02cb4c    LA-2026-3622    96372285-ae9a-45bb-acbf-95d3447b87bb    3c790387-76fc-4fd1-893d-884498cbd8da    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-11-01      \N      permanent       active  \N      \N      2500    without_horse
4291bb46-d0c8-4e02-b3bf-4e8e8fd688c1    LA-2026-4217    96372285-ae9a-45bb-acbf-95d3447b87bb    201edc18-e979-4795-9396-e11f7a579347    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-11-01      \N      permanent       active  \N      \N      2500    without_horse
4f952c41-1621-4e7c-a528-e9ebef8515c4    LA-2026-2693    96372285-ae9a-45bb-acbf-95d3447b87bb    5fb2de9e-1363-42ac-93e7-8504fb0062fd    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-11-01      \N      permanent       active  \N      \N      2500    without_horse
8c90c419-24bd-4104-b2a2-72761f446676    LA-2026-4087    96372285-ae9a-45bb-acbf-95d3447b87bb    06405660-ee33-4a64-a126-b6e072ee6e7c    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-11-01      \N      permanent       active  \N      \N      2500    without_horse
56886b4c-61c2-4aa8-9f34-765efa27fcdf    LA-2026-3668    e2c4ce13-deb5-4561-bdeb-504e3c5f7266    d3e34213-0133-4b50-b5ab-70003980350a    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2026-01-02      \N      permanent       active  \N      \N      4500    with_horse
e39c91ed-d36a-44e7-8c73-dbf93042ed7c    LA-2026-6420    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    67e6b70a-d504-451b-a0b0-fa4072aaaf16    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2025-06-30      \N      permanent       active  \N      \N      5999    with_horse
963ccac2-3504-4977-8cb9-b8ae24be4ecb    LA-2026-7394    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    214bd414-650f-480a-86a5-622c698b63d6    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2025-06-30      \N      permanent       active  \N      \N      5999    with_horse
205233e9-491a-4038-b395-6814c7b98c07    LA-2026-1290    d4ea9dd1-7189-4a84-ab87-e0ae0a8dc19a    9d7e3d1f-744f-4326-a236-1d1f0dc4ab15    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-01      \N      permanent       active  \N      \N      3800    with_horse
047c8299-8c3c-4f81-9b3b-3946c6f72c6b    LA-2026-2572    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    c0d83349-f24a-4c0e-b08c-b9a8d4eca067    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2024-10-01      \N      permanent       active  \N      \N      5999    with_horse
a621e7fd-ea3c-4b02-836b-2146fff023ed    LA-2026-8232    e8918c53-5c87-4e2d-86f9-91276d63bf0d    fd088d87-96f7-442c-8fe3-9e7175b506be    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-01      \N      permanent       active  \N      \N      3500    with_horse
1a8dc5f7-44c2-4c71-b573-0289a6792c3f    LA-2026-5421    a6aa0f45-4b7a-4657-9a53-e80c16232d05    fe89df4f-307e-4a15-9080-56e50739987d    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2026-02-01      \N      permanent       active  \N      \N      4500    with_horse
4b976b15-0ba5-487b-bbb6-6b83753c2e0a    LA-2026-9507    4939968f-1b46-4d2b-83ed-7c1a29806579    07f4f82d-42f5-46b0-b293-ecfc732178c8    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-08-25      \N      permanent       active  \N      \N      4500    with_horse
e94133b4-ba36-4078-ab67-9e3c1ce0e3c7    LA-2026-1670    e6d95ffc-10c1-499e-b300-17235bcb2aee    6a8b068d-9544-4486-b976-3b360a04e42f    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-04-08      \N      permanent       active  \N      \N      4500    with_horse
c248c9d9-2483-44e1-9480-3a26da27f876    LA-2026-0712    e151d01f-d544-41aa-9ace-ffc81e3ce21c    6b3a2f08-412d-4c8e-8716-214e91fa8dad    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-02-02      \N      permanent       active  \N      \N      4500    with_horse
11dcfe17-4df5-4c59-863a-f3b8fe6158af    LA-2026-8936    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    f6f9bdd3-a85e-4e54-8dd2-4bbb2581baff    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2024-10-01      \N      permanent       active  \N      \N      5999    with_horse
dde5166e-43e3-48b8-ac0d-8b5d43f04031    LA-2026-6357    4fdefbef-e962-49a6-bf13-038702cc3fec    c913f90f-2b84-45de-86fd-2d0ea336bb3d    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-01      \N      permanent       active  \N      \N      4500    with_horse
6252dd06-7948-44c3-8b76-8e1e01b62622    LA-2026-9130    919286ed-0bd5-482e-b7a8-75c925386a41    d1e0d953-04b6-4787-9de3-ed0379f4b00f    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-02-04      \N      permanent       active  \N      \N      4500    with_horse
f23d4cb8-8ec7-4549-8f86-d7547d5e176f    LA-2026-7433    b90e3585-1e2c-43a7-8116-3792346ecb73    2732f6f6-5e0b-4231-8a5f-d9baaeb411e3    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-12-28      \N      permanent       active  \N      \N      4500    with_horse
2c051d7f-c850-4255-9048-f017293c0a97    LA-2026-0242    53188f5a-025a-4154-b876-5e4ae1f220ed    29658560-917c-4df5-8606-bf053689b49a    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-03-11      \N      permanent       active  \N      \N      4500    with_horse
eab9ed85-8908-44b6-97c4-9c087807aa27    LA-2026-1455    53188f5a-025a-4154-b876-5e4ae1f220ed    efd99a5d-7cb1-4fe8-a119-83f8b792cb0f    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-03-30      \N      permanent       active  \N      \N      4500    with_horse
dd81c6d0-b66d-4ce9-82e9-d6e9ad835354    LA-2026-1005    3a68c9e2-1088-48d4-b3ff-17231f380ecc    2eb22dd0-9df6-44af-8174-3e35ac405704    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-03-29      \N      permanent       active  \N      \N      4500    with_horse
6d788b08-240a-4106-8d27-98cfb0ba4640    LA-2026-9442    da6262e1-4a7e-4f91-941e-76f3841efc2a    9d0d7f8d-28e6-408a-a53b-35d285debb35    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-08      \N      permanent       active  \N      \N      3800    with_horse
aa520b85-1ffa-4ee8-9615-078a6ff06db0    LA-2026-3720    8ed90e29-86b0-4cfe-a131-c06cb7413956    383c1069-03c1-4a20-96ce-e89c59cad905    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-06-08      \N      permanent       active  \N      \N      4500    with_horse
b75ea39e-a8dc-49ee-8464-522ec2628f3e    LA-2026-2794    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    2c08a20d-51ff-4b1d-8871-7e2ec0b65568    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
e3e80874-51f0-4279-8602-bd1abb3b5d22    LA-2026-1817    69f1447c-0580-44d2-a699-f4dc2ce56ee5    b0cf9824-3634-4b33-aba1-0990e8cc240f    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-06-02      \N      permanent       active  \N      \N      4500    with_horse
ec654c68-bad5-4830-902a-1dda90e66dda    LA-2026-0683    1e44b508-ea1a-4085-a7d8-91bf6035bfc8    31a83f9d-a6fb-483e-9a85-2289818b6737    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2025-09-21      \N      permanent       active  \N      \N      5999    with_horse
f7967797-3262-41b4-a1fd-0ef55091d57f    LA-2026-0036    1e44b508-ea1a-4085-a7d8-91bf6035bfc8    ea18dd2c-50c7-45b6-b36e-df0f5a847518    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2025-10-17      \N      permanent       active  \N      \N      5999    with_horse
a39fbacb-42ae-48da-920f-4e6122c2dd5a    LA-2026-3105    3e04bf98-2062-484c-8832-a6ac763fb9ac    ccd96396-4450-4c33-90bd-a32e6a3c2e81    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-11-24      \N      permanent       active  \N      \N      4500    with_horse
efd51bad-03ef-4265-91d4-5a6746f23d93    LA-2026-8018    fd7cee81-6479-4a50-89b4-89b4d0354383    eeef71f9-3da4-4028-a349-7688735b2f7e    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-21      \N      permanent       active  \N      \N      4500    with_horse
eab8ab6e-06ef-4a46-87bb-de9cf0611e79    LA-2026-6647    c516087b-5ad6-4896-a90d-b865713b411d    3a3b776f-c4c9-471b-ba2a-136fdb7fd98d    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-01      \N      permanent       active  \N      \N      3800    with_horse
8fbea8dd-a8be-42db-9824-36eaa36b598f    LA-2026-9197    c4a090cb-0a94-4f14-b303-fbdd506bf56c    715087dc-9a65-42de-b107-5ebcf9f0ffce    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-01      \N      permanent       active  \N      \N      3800    with_horse
6a028016-fbde-47c2-a596-73e2aef564f6    LA-2026-5903    05805800-43a9-43e0-837b-16c566ed2767    71c19df3-c323-4213-a8fa-5b5747689085    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-12-28      \N      permanent       active  \N      \N      4500    with_horse
bc66e8b5-2972-4793-bf92-e3e45412faff    LA-2026-0104    0e868cbd-6f1f-433d-973d-8d44728a7d58    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-06-16      2026-03-31      permanent       active  \N              4500    with_horse
c16b9e28-f638-4839-ab11-6d1d257e73f9    LA-2026-0128    909909a9-f7f4-496d-8de3-6e6a5addd566    c305222c-ef2c-4cac-a860-53617169f789    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2024-10-01      2026-05-06      permanent       active  \N              5999    with_horse
e74a728c-e594-46fa-a686-c08b87fd9f9e    LA-2026-2789    1c2d7b81-15a8-4f2f-bafd-f907041a1eb8    5da98fb2-8983-4ea1-a7cb-ca84578a2b47    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2026-05-01      \N      permanent       active  \N      \N      4500    with_horse
2ac7c619-d5f7-4503-b675-8605902700fe    LA-2026-7662    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    da0ab2eb-ca08-4958-a03f-7540f884c56b    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
17b270a3-9b9d-4336-a47d-41a3e0827675    LA-2026-6085    c4a090cb-0a94-4f14-b303-fbdd506bf56c    7842c10d-d9af-4a31-bcb1-c3991a8644ba    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-31      2026-04-23      permanent       active  \N              3800    with_horse
72fba684-3a74-4a4a-9b6c-c21f69482130    LA-2026-4780    221c65cc-86b4-48f7-8e6a-098b2b894273    306983c9-0076-404d-885b-42f1801cfa88    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-10-15      2026-04-29      permanent       active  \N              4500    with_horse
79da59f7-d58a-4792-8285-f4b2903debb0    LA-2026-0835    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    c65e130b-82df-4aad-9207-ecf941199738    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2026-02-22      \N      permanent       active  \N      \N      5999    with_horse
bee8af2a-5fc0-4624-a5ab-7b9eb45f8cfa    LA-2026-9220    b26abac0-0aa1-438a-9023-fd0e36882de7    7a08de89-a9f5-4dd5-8b1a-6ce585b57e76    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-07-09      2026-04-30      permanent       active  \N      The horse will move to Royal Stables.   4500    with_horse
0bef9c96-2792-441d-80a2-6b292d33210a    LA-2026-6218    909909a9-f7f4-496d-8de3-6e6a5addd566    0ee5fcb6-2aa6-426a-9cf8-ce41f46d4d23    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2024-10-10      2026-05-06      permanent       active  \N              5999    with_horse
a6557202-19a3-4645-83b0-9d63395ee786    LA-2026-6651    05805800-43a9-43e0-837b-16c566ed2767    f93cd1d5-a6c5-4e76-8171-a385f3777783    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-12-28      \N      permanent       active  \N      \N      4500    with_horse
ed3408de-2e7e-47ce-95fc-f6f65df2456b    LA-2026-8467    8f423989-21f2-46e2-adf5-6c47f716f5af    ea3d6601-2949-4533-9e49-55c585e7d5f1    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2026-02-24      \N      permanent       active  \N      \N      3800    with_horse
4c73c706-6945-4110-8f8c-c146a54bd964    LA-2026-1844    b6d8a1ce-72af-4a68-b544-0cd212191cc2    286ddcad-9db6-4b76-9e14-b96bb403493a    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-01      \N      permanent       active  \N      \N      3800    with_horse
5acca11a-b92a-4177-86af-ae9f9aaf9915    LA-2026-5109    1c291ce0-4b3a-4765-a88a-6eddae18455d    c6e77b87-6119-4743-81a3-c10f648599dc    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-11-01      \N      permanent       active  \N      \N      3800    with_horse
af10d581-1db5-4b16-bac8-e1b28c6ec705    LA-2026-9002    8f423989-21f2-46e2-adf5-6c47f716f5af    3cead808-232f-4d8a-926f-f3c84c731211    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-11-01      \N      permanent       active  \N      \N      3800    with_horse
9f97e0fe-86ab-4a73-99f2-f16d7e7a34e9    LA-2026-5384    1c291ce0-4b3a-4765-a88a-6eddae18455d    3bae3844-10d8-4140-b2fb-468b35bd5640    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2026-02-24      \N      permanent       active  \N      \N      3800    with_horse
2bcd2cdb-3340-4a88-80a5-25973253933b    LA-2026-4973    f7fee818-ae88-449d-aecb-619f7f448da9    cf2395f2-80d5-46cc-b770-45a05f0f8583    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-11-01      \N      permanent       active  \N      \N      3800    with_horse
a78ae6cb-eca2-4902-ad6b-dbdeb506d4e9    LA-2026-0398    1c291ce0-4b3a-4765-a88a-6eddae18455d    596ce3b8-9c3b-410c-9385-87d1388e78dc    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2026-03-07      \N      permanent       active  \N      \N      3800    with_horse
470b1df7-928d-4c53-bded-d00cc7db60fe    LA-2026-6754    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    c2210c19-cee9-4e94-8126-03a399249ebf    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
10dcb153-7fea-4383-ab58-f1c112af5a70    LA-2026-8666    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    afa6afc6-3dcb-4dc4-bf5f-290ed1ef44c8    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
e29364a3-3422-4849-9b8a-9bc621cd7a37    LA-2026-4893    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    ea0ac33a-7727-4835-8b19-143a7e6bd56c    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
a301d561-15ea-4ee8-97b3-7d574e7938a8    LA-2026-3520    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    b4d357fd-5b04-4378-b379-9f1632d96143    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
828f4d13-1d9c-4155-8bd0-fb2178999f79    LA-2026-7690    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    53662acc-b1ed-4158-887e-5234d928404b    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
2c9cff1d-7b6b-4a53-9dc0-081b2446df3f    LA-2026-8312    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    08dfae91-b9cd-452b-b102-2baa08b36165    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-06-24      \N      permanent       active  \N      \N      0       with_horse
85247fa6-758f-4ceb-a245-83f03be36b85    LA-2026-4076    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    8608c09e-7c7b-4298-a828-aa5e54a9aa9a    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
e2d47b81-6601-4db4-bea4-364757be60c7    LA-2026-7647    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    f719dd6b-4a6e-4344-9018-02d2ca8267f0    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-08-24      \N      permanent       active  \N      \N      0       with_horse
84dcd7f8-dbf2-43af-992d-970c2a8ba64b    LA-2026-3680    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    fc59e00d-7f34-4dbf-9e22-f5d201ca748f    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-20      \N      permanent       active  \N      \N      0       with_horse
73fe9898-b3a5-4a88-b687-a3bf947be318    LA-2026-6606    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    490f009a-d7b4-421b-8c9b-a052ead040a9    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
e143a973-3a8c-4626-85ae-8f55f36b75b1    LA-2026-5860    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    381e7902-95aa-460c-ac0c-2fa03883c20e    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-25      \N      permanent       active  \N      \N      0       with_horse
c5493602-a71f-4766-a45d-c2d33bdfcdf0    LA-2026-1252    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    b90bead8-11d0-4782-8147-537cd223d21d    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
44ea6aca-3b79-4b70-b050-2c11e929a942    LA-2026-5328    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    e26c7447-d6a7-4f97-9fed-863110a73d89    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
94663740-d04f-443a-8309-17780d884077    LA-2026-1704    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    b1c71e70-c705-4779-bff3-d8ab0bf231f4    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-17      \N      permanent       active  \N      \N      0       with_horse
3ecae716-2aa4-4f29-bd63-759f080bb711    LA-2026-1388    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    dd80eaa8-0d46-4c1c-94bc-84b3103406f2    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-08-30      \N      permanent       active  \N      \N      0       with_horse
f80fb283-a9bd-4032-b94d-2cc7604552fb    LA-2026-4718    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    9ead1266-5a16-440f-9816-965061849531    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
bef56d65-f228-497a-af24-0bbfac64703b    LA-2026-8585    fe065f3b-9eeb-4682-827f-6f2c25743883    26379f79-ec39-45f2-97f8-b60de93f0e25    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-07-02      \N      permanent       active  \N      \N      3800    with_horse
9b1d42b7-9ac4-4d7b-aa6a-e5a9e3421dc9    LA-2026-2457    369d0d0f-5c75-422f-b983-695a04a7f883    c38baf65-24a8-48a8-b5d9-0b51962718c5    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-21      \N      permanent       active  \N      \N      4500    with_horse
55cdf57d-db44-436d-a52f-2ea5948ad0f1    LA-2026-1735    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    5b1b3a5a-6f46-4bf6-8ffb-eb7b887c0153    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
5da92382-674f-4dca-8d50-ecd03859ab13    LA-2026-9298    7f34854a-d81f-40ff-b4ec-b2671dcf95ff    bfdaa14a-0158-4eae-9acf-7f58d4b99863    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-26      \N      permanent       active  \N      \N      3800    with_horse
d0ff2a0f-c59b-4bfd-9f75-b28ca81b75bf    LA-2026-8953    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    ea9b80fb-7a90-4223-b33b-7b79bf0256a5    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
d46e6d55-a2ea-4c35-b75b-5d1d88bbdbb3    LA-2026-7409    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    c2e10b2e-d645-4752-9bf5-a704453047ef    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
91343df2-d3fe-4165-a5e4-0729f87b6324    LA-2026-5853    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    b599127a-3545-4e8c-9a02-c6e0a8a9a021    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
8247d7cc-052e-4622-86d5-d24c23a24c0c    LA-2026-5456    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    f3ea3726-2d36-4112-8a3f-a14973c47106    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
67f16924-16a3-45ef-95db-b50e501666df    LA-2026-8874    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    ca2da968-1d13-40a6-9ce9-80a3451cc0b5    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
e06ccadb-ed0a-4c88-acdf-5d2d5691ef6b    LA-2026-3461    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    14bd38b2-cc6d-45cd-a8ec-7e619ae363c9    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
971f6b22-4336-41e8-80d4-f38943f36f2c    LA-2026-4646    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    88db7ecb-cfb3-407b-b149-0dd7de29f641    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
ed861515-3b31-491a-96b4-49e913e32add    LA-2026-3559    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    85489880-a902-46e7-b9ce-47a7b87c0e55    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
577d1b72-adb1-4bb2-bfa8-52b4568bbfab    LA-2026-8381    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    715646b2-6870-49eb-a9f4-fc55f21db630    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-26      \N      permanent       active  \N      \N      0       with_horse
da821b07-eda4-4b44-a037-b4492435ab51    LA-2026-8185    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    1d3b9632-116a-4cd9-9a0f-6af24740d36d    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
41742b12-84bb-4cb5-be32-9d2d6cc319f5    LA-2026-1874    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    e14cb4f7-02d5-4417-adb0-78cb5caa71f1    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-26      \N      permanent       active  \N      \N      0       with_horse
c5d40c6c-a163-4725-9d28-ea3912782fd6    LA-2026-4312    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    3be807e9-0a9c-419a-8710-f323e5d82ba1    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
fd6ca2a2-edd8-4717-999e-00d94d14092e    LA-2026-2086    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    9e6d419d-be37-4418-92cc-33b2e3db17dd    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
1696abad-761a-4397-a148-408e36a6c286    LA-2026-1681    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    b10d2896-646e-498e-af78-c8b13b1c5fd3    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
bdcadd5f-3168-4767-ad61-8cf94dcf97a2    LA-2026-1073    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    b60db2ad-d999-456d-b56d-b0e210f0c250    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-26      \N      permanent       active  \N      \N      0       with_horse
cb3ef667-f440-4d62-bead-3ef77e6e74ae    LA-2026-6209    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    db44b2dc-291f-4053-b285-daf9342bdb16    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
e20e6baf-10b6-403b-8695-189898e5d124    LA-2026-2278    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    26ea949a-8ce1-4ddf-9e0b-4bd6567aab2f    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
3bd58602-8159-4f6a-b65e-4119e546db1d    LA-2026-4620    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    6f0b6748-5c51-4100-9b64-66058ab10ebb    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
be843786-6f31-4e06-a062-afb82ad39291    LA-2026-2825    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    6de10c03-eee8-431d-9886-c5dc5b98efef    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
13562d64-eb5d-4764-bbad-bf3afa332fc9    LA-2026-7940    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    bdfc656c-12c5-4858-8ba1-c7b108b17e2e    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
4ff9ff90-c128-4e3d-a982-3b5f34657acf    LA-2026-2348    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    74bb3a04-592e-4f25-a9ec-0511d1e2a8ee    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
efea762f-d6d7-422b-91a1-01e4e94feb4a    LA-2026-8568    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    ffa87a9b-1596-4f69-99d5-5b8cc6b01487    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
62fdb2a4-1bf5-495b-85f0-f442d530e98f    LA-2026-6781    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    b129d22c-4c07-4090-830b-9ccd8cea6cd2    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
ee062a5e-08e2-4503-bc70-434f80165f8c    LA-2026-1649    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    ded1129f-2091-4e7e-b655-e86ba6501e45    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
31fadc25-ff42-45ce-9178-a2cb454128bd    LA-2026-1979    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    13009090-2ea8-4cd6-a070-6f86e789ddc0    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
34331cf6-b646-46b1-964a-9e4a2c159b72    LA-2026-5977    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    a80814fa-d452-4428-a3da-7fdf5163b0f1    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
c3602a8b-aa66-4339-aa18-a346bdf3e6e5    LA-2026-3867    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    de282b0d-5fbe-4ea2-b402-814d1f9b1a39    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
bb6d2c20-bce0-4f5a-9c52-2ae89f629072    LA-2026-2271    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    b92a389e-84ce-4698-a547-506d0b6eb7d5    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
bfe80498-2b3f-43bb-9cee-2ca25e65c755    LA-2026-3900    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    890410e0-e08b-4b50-acf1-722e3689f566    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
7a38b68d-9dfd-4ebd-ad20-c09127aaab0a    LA-2026-9273    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    da79a244-bc94-4497-8c03-4fd84f028b6b    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
492838e1-af27-4170-9f04-44c414a6ac8b    LA-2026-5775    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    eb6035c9-e416-4d1d-a76b-96ca68ea5e2d    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
023bb5e6-d199-47f5-98ac-e56852e328eb    LA-2026-3847    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    513e6d4a-7dd8-4430-8b5a-f60f305da19f    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
40512c80-33d1-4387-92cf-5e2de183cd83    LA-2026-4393    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    bea81e77-b3b2-4f51-bccc-a205b0ef1d3b    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
cbc5ff28-d107-4579-b6ae-9821d98d9953    LA-2026-7927    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    cd23bd11-d682-4018-8d8d-469929891b2a    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
100098a1-7623-45d0-98bb-9cc27df24f97    LA-2026-5059    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    ffac5902-fe2f-435d-8487-fd9dee136dda    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
4c591c4e-0bb5-4883-9efc-fd68ac6d86c8    LA-2026-7265    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    f187473e-04a7-4e38-ab67-1a9089b27270    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
3a43dba1-7064-404a-885b-235a91e3e3ad    LA-2026-7924    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    65297e5e-6f0c-4679-bc90-f77205b88e9f    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
118851e3-bb70-40b4-baef-e0b166aaeb33    LA-2026-8620    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    940ce4e7-bde8-4180-bfd5-4616b6cc9679    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
aa2debbf-65cc-401c-a893-7118db8776dd    LA-2026-5182    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    cc285778-b716-4c19-9fd1-b938b97ace63    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
22611492-a4e5-4508-ab53-73603061e29b    LA-2026-3446    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    1d1bee69-3040-4551-83fc-2e0824779e61    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
b547cd06-f025-41ff-ac1f-c737fa25b992    LA-2026-4831    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    3406ef48-3fa5-489a-b422-115cd514bdf1    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
01023848-27f2-4fa9-9353-898ff9671bb0    LA-2026-4773    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    a9f49b28-fd08-4c9f-8455-300e6d86963d    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
953f8e4e-0fdd-4c25-b5d5-1675d60f68c4    LA-2026-3801    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    46aa0262-f8e5-4595-b558-7ab4c1abdf61    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
ccd73b21-f66a-45a9-a7df-485375938b68    LA-2026-9381    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    d2ca6e4d-e86a-45d0-9ef0-70e63f0fe65c    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
b63523f0-981b-4213-9cf8-36b308363c6b    LA-2026-0495    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    bbeef4fc-b1e6-4977-98c5-420d84869653    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
24b5874e-1fe7-40a3-9654-3885b72045c6    LA-2026-7644    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    1f222285-3e81-44ed-8cee-2e31e1e47a97    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
ed0c7101-2f4b-4594-8e09-b70868861062    LA-2026-4769    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    08c28d47-9061-40ad-9dd6-b8a97c2e885a    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
769d85ae-f864-439a-a401-3ee6f272353c    LA-2026-8436    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    706522da-797c-49d3-918c-891db403993c    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
37a6eabf-8f3b-4993-9797-563a9f1b0565    LA-2026-2234    3901dd23-92c5-41d6-9b65-b4b356d1d862    2a5d586a-b056-44cf-8cd1-a35b634adcdd    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2026-04-01      \N      permanent       active  \N      \N      5999    with_horse
f92e40f0-3188-4b4b-aac7-2a9386ca9814    LA-2026-6688    3901dd23-92c5-41d6-9b65-b4b356d1d862    a6b06986-d142-4366-90dc-64f5ab23ab78    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2026-04-01      \N      permanent       active  \N      \N      5999    with_horse
9b025149-2c56-4dbd-80ea-2c2849edb1f9    LA-2026-1989    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    f3b85547-5092-4f72-bf25-b65a010c58fd    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      0       with_horse
8333f845-50bc-486c-a59f-49ff8f1eb377    LA-2026-9975    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    1a07b38b-dd8a-436d-acd9-c187de153ac0    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      4500    with_horse
36e479ca-f1d5-41d1-be08-f0d995046e98    LA-2026-7522    bfc896d6-ea39-4ddf-8d92-0fbb1762ca04    27d39b5b-c47c-44a4-903e-5a01f8e181e9    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-25      2026-03-31      permanent       active  \N              4500    with_horse
bd4d6227-5901-4ed9-8f36-54c3c149c7ae    LA-2026-9953    fe065f3b-9eeb-4682-827f-6f2c25743883    cb6a2ab2-ee83-4b90-a3d2-c8a6ac6a55fa    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-09-25      2026-04-27      permanent       active  \N              3800    with_horse
ea0db11a-b11e-4702-9c7c-3016963760ae    LA-2026-2200    5f217e94-85d7-47aa-b137-94a3c293c35c    a646641d-afe4-45c1-a126-1190cfc13fc1    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-01      \N      permanent       active  \N      \N      3800    with_horse
de7d1200-1908-4458-a02c-1e8d437ea3c5    LA-2026-8978    5f217e94-85d7-47aa-b137-94a3c293c35c    e6ca296b-f4e3-4a24-81ed-53b87916b1cc    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-01      \N      permanent       active  \N      \N      3800    with_horse
b4e9ffd0-976f-492a-8324-5bbd870e2e19    LA-2026-4054    5f217e94-85d7-47aa-b137-94a3c293c35c    e8483047-9c30-4a53-b220-9a78857f4515    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-01      \N      permanent       active  \N      \N      3800    with_horse
28925223-03f6-48ec-8e93-219596159d5d    LA-2026-0017    5f217e94-85d7-47aa-b137-94a3c293c35c    493d93c8-a206-4b84-a565-31ce54fb3031    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2024-10-01      \N      permanent       active  \N      \N      3800    with_horse
ec25a7b6-fd7d-40f5-b771-bd1f083f3525    LA-2026-7797    b98e1c14-1b11-4953-b795-ff41a2042572    fb57ff0c-df62-4858-abae-cf4ec4e3170c    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-12-19      \N      permanent       active  \N      \N      4500    with_horse
01b2c104-a7ce-487c-9a6b-77d815d57dad    LA-2026-0402    b98e1c14-1b11-4953-b795-ff41a2042572    99a9b749-b3b1-40ae-98cc-a59a08fdf79f    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-12-19      \N      permanent       active  \N      \N      4500    with_horse
6f387363-b896-4ccd-8019-2efb7c3227b4    LA-2026-4732    b98e1c14-1b11-4953-b795-ff41a2042572    f1c38418-c8c0-4483-bf87-a851e13619aa    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-12-19      \N      permanent       active  \N      \N      4500    with_horse
cc3a2e05-86a2-434f-9e32-fed376886edd    LA-2026-2484    b98e1c14-1b11-4953-b795-ff41a2042572    f58270bb-bc1f-4e0c-a15a-5a0b39b35d6b    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-12-19      \N      permanent       active  \N      \N      4500    with_horse
3680a313-2b02-45fb-92ed-65d918b9fd63    LA-2026-0426    b98e1c14-1b11-4953-b795-ff41a2042572    09264a61-0b3c-41e3-be12-160077b0e7a3    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-12-19      \N      permanent       active  \N      \N      4500    with_horse
cfb5dbf4-9e82-4a73-ac68-903b5c34be3a    LA-2026-3144    b98e1c14-1b11-4953-b795-ff41a2042572    830babf1-8dbb-4061-8a4a-c44797d113af    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-12-19      \N      permanent       active  \N      \N      4500    with_horse
b119218e-858a-4c49-a7e6-922b8867bd3a    LA-2026-9020    6af4bc47-b9fd-4f56-8725-ab513f7eb94f    dd15bef2-8ae0-4f37-a97b-5e6267616863    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2025-05-14      \N      permanent       active  \N      \N      4500    with_horse
98176849-c1f5-4bbd-8041-c9b4f3270c44    LA-2026-8895    3901dd23-92c5-41d6-9b65-b4b356d1d862    51f2090e-54fe-4c1a-82d2-b81b5b883dbf    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2026-04-30      \N      permanent       active  \N      \N      5999    with_horse
68358b63-163c-4e04-89b4-0b875713c96d    LA-2026-8428    2ac641cb-e76f-47c1-9361-10488823595a    d92188a3-d9d5-405e-b88f-5c8a7b3c60c1    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2026-05-10      \N      permanent       active  \N      \N      4500    with_horse
19397653-4da2-40f5-a33d-1fb6350c2cb5    LA-2026-8260    07cc6f8f-59e4-4d50-a1a1-f2e751b9758b    7842c10d-d9af-4a31-bcb1-c3991a8644ba    ddd7d6f3-ed3b-48d1-80fd-30cbaff90e6d    2026-05-24      \N      permanent       active  \N      \N      4500    with_horse
d0cdf354-5cf5-4ab4-bb91-f678eb63637c    LA-2026-6487    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    7a08de89-a9f5-4dd5-8b1a-6ce585b57e76    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2026-05-28      \N      permanent       active  \N      \N      5999    with_horse
8e4e40ab-9a5a-47eb-b8a7-601eed34fe70    LA-2026-6360    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    c305222c-ef2c-4cac-a860-53617169f789    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2026-05-28      \N      permanent       active  \N      \N      5999    with_horse
0e5b97e5-d40c-4441-af32-7e0c0b4ebeb2    LA-2026-2146    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    0ee5fcb6-2aa6-426a-9cf8-ce41f46d4d23    48ac9592-3ac7-4b32-a92a-dc80d02c3089    2026-05-28      \N      permanent       active  \N      \N      5999    with_horse
\.


--
-- Data for Name: monthly_billing_approvals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.monthly_billing_approvals (id, customer_id, billing_month, step, user_id, approved, created_at, updated_at) FROM stdin;
699aec28-fff7-44af-8b56-6b23998bc556    8cd719bb-46a3-463c-be83-24ae1928f357    2026-04 STORES  853acd7c-4759-4213-ace1-b7da16385a52    t       2026-04-23 08:53:50.652529+00   2026-04-23 08:53:50.652529+00
3c17c2cb-2a86-47d2-9152-78a29d9bccd5    e2c4ce13-deb5-4561-bdeb-504e3c5f7266    2026-04 STORES  50714bb1-7f0e-4363-b470-1c7af22870d4    t       2026-04-25 10:47:28.41594+00    2026-04-25 10:47:28.41594+00
3b7c20b3-a657-49b1-b667-efa41510ac20    53188f5a-025a-4154-b876-5e4ae1f220ed    2026-04 STORES  50714bb1-7f0e-4363-b470-1c7af22870d4    t       2026-04-25 10:47:38.583314+00   2026-04-25 10:47:38.583314+00
84c66e0a-f847-4136-a6e3-f8bbebd50dd8    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:05:31.667097+00   2026-04-27 14:05:31.667097+00
3836f7a6-f4fc-4fae-9b4e-f457dbc533d9    e2c4ce13-deb5-4561-bdeb-504e3c5f7266    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:05:46.748887+00   2026-04-27 14:05:46.748887+00
48fbb2e4-bfdf-4116-aace-ed15b36c2788    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:06:06.463697+00   2026-04-27 14:06:06.463697+00
f04ad57b-5194-4874-b476-cf5734beae3a    d4ea9dd1-7189-4a84-ab87-e0ae0a8dc19a    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:06:16.268903+00   2026-04-27 14:06:16.268903+00
4cadd233-ab31-4261-804a-27da14db053a    e8918c53-5c87-4e2d-86f9-91276d63bf0d    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:06:26.438673+00   2026-04-27 14:06:26.438673+00
37e75419-add5-4ba4-b52d-20a337d90493    4939968f-1b46-4d2b-83ed-7c1a29806579    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:06:35.158384+00   2026-04-27 14:06:35.158384+00
bbfabe4c-94fa-4473-92bd-371a22c53727    919286ed-0bd5-482e-b7a8-75c925386a41    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:06:49.046615+00   2026-04-27 14:06:49.046615+00
a561b140-577d-4785-83c3-75e272b06558    b90e3585-1e2c-43a7-8116-3792346ecb73    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:06:51.067865+00   2026-04-27 14:06:51.067865+00
56db7e28-2832-462b-8227-217c096dfd76    53188f5a-025a-4154-b876-5e4ae1f220ed    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:06:54.855145+00   2026-04-27 14:06:54.855145+00
4de8cce4-c20e-44c9-9fa8-cf56da1d2624    3a68c9e2-1088-48d4-b3ff-17231f380ecc    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:06:57.669629+00   2026-04-27 14:06:57.669629+00
1e87fe49-fa75-467b-934a-99ac7c724488    da6262e1-4a7e-4f91-941e-76f3841efc2a    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:07:00.757344+00   2026-04-27 14:07:00.757344+00
7acb95bb-c575-42a3-b8b9-5e1b37dd6d34    b26abac0-0aa1-438a-9023-fd0e36882de7    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:07:06.520053+00   2026-04-27 14:07:06.520053+00
aa9664c2-c253-4dcc-ac49-931239a06ace    8ed90e29-86b0-4cfe-a131-c06cb7413956    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-27 14:07:08.773115+00   2026-04-27 14:07:08.773115+00
43549c25-8f99-4668-aac5-42d77a539c18    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-04 STORES  50714bb1-7f0e-4363-b470-1c7af22870d4    t       2026-04-28 06:29:10.954343+00   2026-04-28 06:29:10.954343+00
277a15ec-dde3-4744-ae00-a32bf360cf1f    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    2026-04 STORES  50714bb1-7f0e-4363-b470-1c7af22870d4    f       2026-04-28 06:29:23.277939+00   2026-04-28 06:30:14.101792+00
bfe818cd-daf0-49b7-b582-c829ab49f631    d4ea9dd1-7189-4a84-ab87-e0ae0a8dc19a    2026-04 STORES  50714bb1-7f0e-4363-b470-1c7af22870d4    f       2026-04-28 06:29:21.046531+00   2026-04-28 06:30:15.249296+00
e0579cd0-0238-4362-ab22-62a18e56d85b    7f34854a-d81f-40ff-b4ec-b2671dcf95ff    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:50:01.423522+00   2026-06-01 09:50:01.423522+00
c6279da9-c25d-49e4-9612-b99080692a9e    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2026-04 STORES  50714bb1-7f0e-4363-b470-1c7af22870d4    t       2026-04-28 06:29:14.144362+00   2026-04-28 06:30:19.453283+00
70639747-3c0a-4226-9b08-9932fde70329    4939968f-1b46-4d2b-83ed-7c1a29806579    2026-04 STORES  50714bb1-7f0e-4363-b470-1c7af22870d4    t       2026-04-28 06:30:31.285656+00   2026-04-28 06:30:31.285656+00
2bcfb5ee-7acd-466c-b64c-7062188c69f5    af441b86-4b9a-4810-9cdd-7af4f886aef6    2026-04 STORES  50714bb1-7f0e-4363-b470-1c7af22870d4    t       2026-04-28 06:30:52.815537+00   2026-04-28 06:30:52.815537+00
d4518bdd-7a4a-42d2-87e8-231d1a1a5458    8cd719bb-46a3-463c-be83-24ae1928f357    2026-04 VET     853acd7c-4759-4213-ace1-b7da16385a52    f       2026-04-28 05:35:45.552247+00   2026-04-28 07:48:43.109869+00
2d9768a3-7762-4f66-8f93-562a3fa6e254    af441b86-4b9a-4810-9cdd-7af4f886aef6    2026-04 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-04-28 10:56:35.434367+00   2026-04-28 10:56:45.098492+00
0925c168-8e2e-4fcc-b07d-3731d15d0139    3fe1302f-fad6-42cd-915e-acef194e13c6    2026-05 VET     853acd7c-4759-4213-ace1-b7da16385a52    t       2026-05-01 10:09:53.049978+00   2026-05-01 10:09:53.049978+00
befc6786-4bc3-4886-8f55-04fffc6a8dd6    3fe1302f-fad6-42cd-915e-acef194e13c6    2026-05 STORES  853acd7c-4759-4213-ace1-b7da16385a52    t       2026-05-01 10:09:53.907444+00   2026-05-01 10:09:53.907444+00
338cd23a-7349-411b-a4bf-14679314498d    c0471f15-cf19-4ac7-87da-2931db694ddd    2026-05 STORES  853acd7c-4759-4213-ace1-b7da16385a52    t       2026-05-01 10:10:15.147547+00   2026-05-01 10:10:15.147547+00
7540c0a9-27a0-44ff-8972-db828aa1b164    c0471f15-cf19-4ac7-87da-2931db694ddd    2026-05 VET     853acd7c-4759-4213-ace1-b7da16385a52    t       2026-05-01 10:10:15.961442+00   2026-05-01 10:10:15.961442+00
a7e0c5db-4c95-438e-8869-3a543606f695    3901dd23-92c5-41d6-9b65-b4b356d1d862    2026-04 STORES  853acd7c-4759-4213-ace1-b7da16385a52    t       2026-05-04 07:30:20.351313+00   2026-05-04 07:30:20.351313+00
db8f6385-ca75-4c30-8e40-944e2a71109e    3901dd23-92c5-41d6-9b65-b4b356d1d862    2026-04 VET     853acd7c-4759-4213-ace1-b7da16385a52    t       2026-05-04 07:30:22.751661+00   2026-05-04 07:30:22.751661+00
04794f68-cd75-4a07-b2e1-5bd03908d34d    8cd719bb-46a3-463c-be83-24ae1928f357    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:39:29.509439+00   2026-06-01 09:39:29.509439+00
85e59f96-7082-4d49-aed6-7eee38367d8f    96372285-ae9a-45bb-acbf-95d3447b87bb    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:39:55.571327+00   2026-06-01 09:39:55.571327+00
b62a5a68-335e-4945-83bf-9b6544ca8a5e    e2c4ce13-deb5-4561-bdeb-504e3c5f7266    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:40:00.371009+00   2026-06-01 09:40:00.371009+00
57c3243c-a8c6-4d9a-8786-310247633fb9    ccf91a19-f2fc-4552-b4c6-c8f18b84216d    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:40:28.416897+00   2026-06-01 09:40:28.416897+00
c8bd65e9-3c3f-4d36-8384-190495504784    d4ea9dd1-7189-4a84-ab87-e0ae0a8dc19a    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:40:34.162214+00   2026-06-01 09:40:34.162214+00
82989572-76ea-4d8d-84e8-2bd26e4e4b5d    56e9ca2a-26c5-4ddb-9a06-9d164eeabb06    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:42:22.329172+00   2026-06-01 09:42:22.329172+00
532a7e35-e434-4e14-b3be-44856ef22046    e8918c53-5c87-4e2d-86f9-91276d63bf0d    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:42:27.120491+00   2026-06-01 09:42:27.120491+00
11f0fb00-f423-4b9c-8740-1dcb79238e0a    a6aa0f45-4b7a-4657-9a53-e80c16232d05    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:42:38.235191+00   2026-06-01 09:42:38.235191+00
aec20ede-5648-4870-b467-0242a87cf1c0    4939968f-1b46-4d2b-83ed-7c1a29806579    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:42:40.218134+00   2026-06-01 09:42:40.218134+00
3766a433-12c3-40aa-88b8-387c9d86250f    e6d95ffc-10c1-499e-b300-17235bcb2aee    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:46:26.376715+00   2026-06-01 09:46:26.376715+00
19ef25e2-409e-4829-a2fc-91284433f060    e151d01f-d544-41aa-9ace-ffc81e3ce21c    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:46:31.151425+00   2026-06-01 09:46:31.151425+00
b981e7f2-b006-4156-b8f5-8850002e60c9    4fdefbef-e962-49a6-bf13-038702cc3fec    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:46:37.230756+00   2026-06-01 09:46:37.230756+00
1ff6542c-5bcc-4513-9db8-35ba7e047720    919286ed-0bd5-482e-b7a8-75c925386a41    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:46:39.981158+00   2026-06-01 09:46:39.981158+00
47e4d7f1-397a-4f01-8a8c-68a050b0c62b    b90e3585-1e2c-43a7-8116-3792346ecb73    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:46:43.06651+00    2026-06-01 09:46:43.06651+00
055ea367-2221-4cf3-991c-3ce1bb7572d0    53188f5a-025a-4154-b876-5e4ae1f220ed    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:46:48.666278+00   2026-06-01 09:46:48.666278+00
e58df31a-ba23-4ac9-911d-4a6febbae5b2    3a68c9e2-1088-48d4-b3ff-17231f380ecc    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:46:51.408848+00   2026-06-01 09:46:51.408848+00
6968a32a-8f0f-4ab7-a786-8b5bd71faad0    da6262e1-4a7e-4f91-941e-76f3841efc2a    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:46:53.304392+00   2026-06-01 09:46:53.304392+00
5862869d-9142-4342-874a-468b28adde30    8ed90e29-86b0-4cfe-a131-c06cb7413956    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:46:57.040177+00   2026-06-01 09:46:57.040177+00
3e292297-8dc0-4d06-9cd4-2fdd1489a6f9    69f1447c-0580-44d2-a699-f4dc2ce56ee5    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:47:14.098081+00   2026-06-01 09:47:14.098081+00
663a1967-6be7-4fe7-852f-72b4143af51d    1e44b508-ea1a-4085-a7d8-91bf6035bfc8    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:48:38.381073+00   2026-06-01 09:48:38.381073+00
1b728e75-3bc6-4521-b0c9-d636df391bbd    3e04bf98-2062-484c-8832-a6ac763fb9ac    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:48:40.323353+00   2026-06-01 09:48:40.323353+00
b8dbc24a-993c-4c94-943b-e3226b175cef    fd7cee81-6479-4a50-89b4-89b4d0354383    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:48:42.556495+00   2026-06-01 09:48:42.556495+00
63d75419-67d6-4ae9-a6ea-adeaa7e6ffa0    c516087b-5ad6-4896-a90d-b865713b411d    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:48:44.688671+00   2026-06-01 09:48:44.688671+00
69328bf1-6b23-4e80-9d4f-c5d7abde9a33    c4a090cb-0a94-4f14-b303-fbdd506bf56c    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:48:47.285649+00   2026-06-01 09:48:47.285649+00
b322a8d0-f3cf-4768-885f-7cca59a87d50    05805800-43a9-43e0-837b-16c566ed2767    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:48:54.467698+00   2026-06-01 09:48:54.467698+00
e9bab2b7-8705-4f45-875d-b7f8950d6c74    909909a9-f7f4-496d-8de3-6e6a5addd566    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:49:01.110302+00   2026-06-01 09:49:01.110302+00
5ecfaf9b-be1d-4b3b-bf9f-ad0391c5b2dd    1c2d7b81-15a8-4f2f-bafd-f907041a1eb8    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:49:04.618271+00   2026-06-01 09:49:04.618271+00
b37a76bf-0bab-407f-bfdb-46291573330f    8f423989-21f2-46e2-adf5-6c47f716f5af    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:49:25.165606+00   2026-06-01 09:49:25.165606+00
4823606e-783f-4b8a-b46a-96c5d24c1564    b6d8a1ce-72af-4a68-b544-0cd212191cc2    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:49:38.33873+00    2026-06-01 09:49:38.33873+00
0fe9eb77-153a-4fc8-ac89-dbb45f9cc2e8    1c291ce0-4b3a-4765-a88a-6eddae18455d    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:49:46.772483+00   2026-06-01 09:49:46.772483+00
545023ec-1792-4330-b817-70ece6da0a29    f7fee818-ae88-449d-aecb-619f7f448da9    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:49:49.913547+00   2026-06-01 09:49:49.913547+00
cdedd04b-59d7-4efa-8eba-61dd8ab79e71    fe065f3b-9eeb-4682-827f-6f2c25743883    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:49:52.301929+00   2026-06-01 09:49:52.301929+00
856d3e6f-e5b0-423d-9c75-84134dc1f28a    369d0d0f-5c75-422f-b983-695a04a7f883    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:49:56.857228+00   2026-06-01 09:49:56.857228+00
dbbac283-cb42-48b9-8b03-0e3f690dd920    5f217e94-85d7-47aa-b137-94a3c293c35c    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:53:56.834881+00   2026-06-01 09:53:56.834881+00
b137e999-ed33-47bb-a774-8b18b34ad489    2ac641cb-e76f-47c1-9361-10488823595a    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:54:45.913062+00   2026-06-01 09:54:45.913062+00
19b13a42-3a19-4d08-9377-8c5446814884    07cc6f8f-59e4-4d50-a1a1-f2e751b9758b    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:54:50.116464+00   2026-06-01 09:54:50.116464+00
7b80a918-e230-4bb7-9cd8-8b5f98fe44c1    297dd6e6-0736-4735-b670-eb51444f8a21    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:54:58.18625+00    2026-06-01 09:54:58.18625+00
fff561ed-f5b7-4f29-81b6-2340c1f1721b    53946bbc-2874-45af-ad7e-6d3d52dc0c25    2026-05 VET     3823058b-4ef5-4c22-913f-9cd149cbb6e0    t       2026-06-01 09:55:09.393273+00   2026-06-01 09:55:09.393273+00
\.


--
-- Data for Name: session; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.session (sid, sess, expire) FROM stdin;
7Q7EaOxDcIbcHWdFRb7RIlyYBr5EJEL1        {"cookie":{"originalMaxAge":86400000,"expires":"2026-06-02T05:22:25.064Z","secure":true,"httpOnly":true,"path":"/","sameSite":"strict"},"passport":{"user":"853acd7c-4759-4213-ace1-b7da16385a52"}}     2026-06-02 10:00:59
3fPzNTSbXmTyeTFmYodVmKlOJ3ewq6uM        {"cookie":{"originalMaxAge":86400000,"expires":"2026-06-01T07:13:46.691Z","secure":true,"httpOnly":true,"path":"/","sameSite":"strict"},"passport":{"user":"5f2a1d87-9068-4f91-bf5b-34c55b5b9fa4"}}     2026-06-02 06:17:10
uDuiDb3SjHOp5duuomMAOS3lVBkd_m2w        {"cookie":{"originalMaxAge":86400000,"expires":"2026-06-02T05:47:17.224Z","secure":true,"httpOnly":true,"path":"/","sameSite":"strict"},"passport":{"user":"51e90911-2110-4d9b-8278-f7a1b0dd366c"}}     2026-06-02 06:25:44
fMKxAcOLL1Ebe9jOyC1RFWWWc45E8yQn        {"cookie":{"originalMaxAge":86400000,"expires":"2026-06-02T05:41:55.482Z","secure":true,"httpOnly":true,"path":"/","sameSite":"strict"},"passport":{"user":"50714bb1-7f0e-4363-b470-1c7af22870d4"}}     2026-06-02 08:52:43
X1kQz_52Frbkrvco1XUm6gye_-oAHBe0        {"cookie":{"originalMaxAge":86400000,"expires":"2026-06-02T06:26:34.991Z","secure":true,"httpOnly":true,"path":"/","sameSite":"strict"},"passport":{"user":"51e90911-2110-4d9b-8278-f7a1b0dd366c"}}     2026-06-02 06:26:37
2fB5Wv_QdPUCg3YK239DM4E6QsdGOS0L        {"cookie":{"originalMaxAge":86400000,"expires":"2026-06-02T09:21:22.534Z","secure":true,"httpOnly":true,"path":"/","sameSite":"strict"},"passport":{"user":"3823058b-4ef5-4c22-913f-9cd149cbb6e0"}}     2026-06-02 09:55:10
vFGkWGKQVcL22kEFdzXyEJvtozXW2kGB        {"cookie":{"originalMaxAge":86400000,"expires":"2026-06-02T05:12:31.384Z","secure":true,"httpOnly":true,"path":"/","sameSite":"strict"},"passport":{"user":"fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8"}}     2026-06-02 07:05:02
\.


--
-- Data for Name: stables; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.stables (id, name, status, netsuite_id) FROM stdin;
83b8c5d3-48c5-4b50-bb8d-f02ab2daf109    Maha    active  \N
9bf0a6da-104a-4477-b16a-8dc7c09ad751    Damess  active  \N
ac756abd-1920-4fd5-8e2f-ec2bd9965361    Al Anood        active  \N
1da3002a-c3ec-41b1-8f64-1c4f9ec7f2dc    Shaikha Stables active  \N
5023547e-1af7-4840-a647-bf8b216156f9    New building /Jumping A active  \N
c3c53d41-8fc2-4167-83d0-6c86b3fd27a9    New building /Jumping B active  \N
bacdd040-4e44-4b97-81dc-c22fbd3e0d82    New building /Jumping C active  \N
f0b9f500-073f-45c8-bd8c-0852ccbedb3d    New building /Jumping D active  \N
4d6524dd-0e9f-44f9-8222-132ef9408f75    New building /Jumping E active  \N
12deffac-f07e-4eae-8f26-516a007733a4    New building /Jumping F active  \N
b39ef8a2-5b12-4e84-ae4c-0647abb768e2    New building /Jumping G active  \N
36748823-6554-4f94-8833-19220605bdb8    New building /Jumping H active  \N
832851bb-7b7c-4294-9c42-5dd71fff0447    New building /Jumping I active  \N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, username, password, role, sso_id) FROM stdin;
932b73f2-51b9-42f9-805a-da2409661b9a    jassim.shanavas@adec.ae fce5e787378cb6942a6b6c9c12d7cab1ef61ee63d0372522c3f44387a959a82e87057c66f8a703aebe1d7dc9321a1e1309b2934b04a1c10c7284b49a464118a0.91dfaeffae2ce4e7f72ee0ed8ec130d8       FINANCE \N
3823058b-4ef5-4c22-913f-9cd149cbb6e0    orla.ohanlon@adec.ae    fdda272903c00c33669db941a6d630805c5cf58786197c495c8fdd96dee422b1b58e67475289f1efd51787681af3947a5cdcd965f177d3e02474ea890d78fbda.41651980b19a2dd0ad4d0d8965222698       VETERINARY      \N
ef15f912-26cd-4a82-b345-2e20f4706490    nixon.silveira@adec.ae  5595663a2addba760699cd3bf85194b58813224476f1e570bd8306d25f108f7aa3f257490e5ae8f02493076b03b97cc6909efe5ada02220042b9c74de7e5f2fa.db23bffd868b5f032cd13fdcdabdb66e       VETERINARY      \N
50714bb1-7f0e-4363-b470-1c7af22870d4    Muhammad.saad@adec.ae   d086fcf1b2500300581241933c9e3d030119780195fe47a00ea8d8c0046749f0d96443b3ed0afe2f836617970eb7b5dc6a069cd3c3403c7b415c54d117269c3a.60b2589213d71eb8f4c8b572b19fc2f5       STORES  \N
fff0ac33-ae4c-439a-97f6-7cbbf3cb99a8    andrea.villarin@adec.ae a82a1608a99322cecdec816e1d45ef0ab17ee2378fd5d553b72331d600ad45a879446a0dee04fda2e3ebe83c88ba6935423ec851ec27f0c703b992e95a424e67.db62ff1807a842aab570e843cba77e02       LIVERY_ADMIN    \N
853acd7c-4759-4213-ace1-b7da16385a52    admin   4a6599e2dbbbf525ace9dfe5e9f40a5cefabbed098651b096307942e46137901c0dd8dc68d52f796fd624e924fd5af064dc07ed253fc7b68ff2a44de84e94f75.bdcdc007a85f5a4defdfdc2f1deae729       ADMIN   \N
5f2a1d87-9068-4f91-bf5b-34c55b5b9fa4    radhakrishnan@adec.ae   6a4512df01d36e6a63db2c3850a6f88d8d7d8f2d67173944776a7c217770844066b7287a9049872115f90efc5f94f5349d73e3cf891877d71e372e3d885e373f.8318556da7f91f6276fd588369fd421b       ADMIN   \N
03a8b97a-eb58-42ad-bbeb-9ebe5de77abf    patrik.wagner@adec.ae   e1653946f8a9a60acfb2f72526e57781cb4856fcce2cc3a6a3d5cfb18564224dde222defc16184acbeeb98dceb569827c7b6b230667c78cd2e326fd36f6f9e91.b45c2a4fc99068ed2aca9c1a94c1c297       ADMIN   \N
51e90911-2110-4d9b-8278-f7a1b0dd366c    Zeid    da739010db7995d05c958370c88446e29084230c618dfac812e615af46384c29497527fe22b51d9b589c2a50826f1d0292121e656a384264ab318b942f6761eb.c0cbb7f1c36adaeea0d487f7529cf30f       ADMIN   e010ca81-e3cd-4205-9f19-916235f0103f
975fbe2a-c8f2-45e9-89d9-9c2fb56ddf2a    varun.mohan@adec.ae     e97d6e460b88d89f2a72cbf2407f753ece2bf759aca04a0f9fa87e28ef577e5b8a874b12fd793e072f4b31ae8464e550c1c0898626da3c96ccf5eb412fb025af.e617f32d1b8e9992b239e9217aa30565       LIVERY_ADMIN    \N
0c0d2601-f01e-45d4-b9c4-e7f10ad68792    hassan.khairy@adec.ae   55a171539e88d20984f2602795834decd6210b5a868cebf5c20c5acb0bb6f49e54a7e2b410f24e515b8a8aedb0616b5f31134bfe9d5aa8371c959e03f4f42929.c9e74d33d0ded05334438c5748c75a6c       FINANCE \N
bebd5b6a-0f1e-47ad-a6f9-cf22e0aae3aa    saleh.shaaban@adec.ae   ad70931afc557770ab8718a2060437cbc4acc06d20e45a63674cbe3ea95aaf8052c64788f499757378fd41b17453dc9518f4a1c632a90b999c22844833eed7da.a9a4c946fc03a395bce94366766666df       FINANCE \N
49fa781f-4c51-4f1f-9fd5-d99eed079912    hagar.shehab@adec.ae    213842cd2be3f6094d5b272f75173d48bfc889081d633b7db902e825f70e6b65eb8c5bc88b2a1ee754ce2128839a6a4ec1276c1566f153aabef2572353bc98fd.33bcc7531e6e23fe96a4c5f62efcf7f0       FINANCE \N
de0adb89-60c5-4188-871d-0a14bb226223    systemadmin     b239f78cba381dd522f6e76fe14dc61849fabb86d980dba17e59c5f3ec6c4f8ec9bd33a67cb9927be3074cb2211b1b58a6b01942b2c4c5d78c148e9e949d9e80.25367ddd3ad349123db4587f10dbb8d0       ADMIN   \N
\.


--
-- Name: replit_database_migrations_v1_id_seq; Type: SEQUENCE SET; Schema: _system; Owner: -
--

SELECT pg_catalog.setval('_system.replit_database_migrations_v1_id_seq', 9, true);


--
-- Name: replit_database_migrations_v1 replit_database_migrations_v1_pkey; Type: CONSTRAINT; Schema: _system; Owner: -
--

ALTER TABLE ONLY _system.replit_database_migrations_v1
    ADD CONSTRAINT replit_database_migrations_v1_pkey PRIMARY KEY (id);


--
-- Name: agreement_documents agreement_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agreement_documents
    ADD CONSTRAINT agreement_documents_pkey PRIMARY KEY (id);


--
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (key);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: billing_elements billing_elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_elements
    ADD CONSTRAINT billing_elements_pkey PRIMARY KEY (id);


--
-- Name: boxes boxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boxes
    ADD CONSTRAINT boxes_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: horse_movements horse_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.horse_movements
    ADD CONSTRAINT horse_movements_pkey PRIMARY KEY (id);


--
-- Name: horse_ownership horse_ownership_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.horse_ownership
    ADD CONSTRAINT horse_ownership_pkey PRIMARY KEY (id);


--
-- Name: horses horses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.horses
    ADD CONSTRAINT horses_pkey PRIMARY KEY (id);


--
-- Name: invoice_validations invoice_validations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_validations
    ADD CONSTRAINT invoice_validations_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_po_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_po_number_unique UNIQUE (po_number);


--
-- Name: item_prices item_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_prices
    ADD CONSTRAINT item_prices_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: livery_agreements livery_agreements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livery_agreements
    ADD CONSTRAINT livery_agreements_pkey PRIMARY KEY (id);


--
-- Name: monthly_billing_approvals monthly_billing_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_billing_approvals
    ADD CONSTRAINT monthly_billing_approvals_pkey PRIMARY KEY (id);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (sid);


--
-- Name: stables stables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stables
    ADD CONSTRAINT stables_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_unique UNIQUE (username);


--
-- Name: idx_replit_database_migrations_v1_build_id; Type: INDEX; Schema: _system; Owner: -
--

CREATE UNIQUE INDEX idx_replit_database_migrations_v1_build_id ON _system.replit_database_migrations_v1 USING btree (build_id);


--
-- Name: IDX_session_expire; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_session_expire" ON public.session USING btree (expire);


--
-- Name: billing_elements_agreement_month_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX billing_elements_agreement_month_unique ON public.billing_elements USING btree (agreement_id, billing_month) WHERE (agreement_id IS NOT NULL);


--
-- Name: idx_monthly_billing_approvals_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_monthly_billing_approvals_unique ON public.monthly_billing_approvals USING btree (customer_id, billing_month, step);


--
-- Name: users_sso_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_sso_id_unique ON public.users USING btree (sso_id) WHERE (sso_id IS NOT NULL);


--
-- Name: agreement_documents agreement_documents_agreement_id_livery_agreements_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agreement_documents
    ADD CONSTRAINT agreement_documents_agreement_id_livery_agreements_id_fk FOREIGN KEY (agreement_id) REFERENCES public.livery_agreements(id);


--
-- Name: billing_elements billing_elements_agreement_id_livery_agreements_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_elements
    ADD CONSTRAINT billing_elements_agreement_id_livery_agreements_id_fk FOREIGN KEY (agreement_id) REFERENCES public.livery_agreements(id);


--
-- Name: billing_elements billing_elements_box_id_boxes_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_elements
    ADD CONSTRAINT billing_elements_box_id_boxes_id_fk FOREIGN KEY (box_id) REFERENCES public.boxes(id);


--
-- Name: billing_elements billing_elements_customer_id_customers_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_elements
    ADD CONSTRAINT billing_elements_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: billing_elements billing_elements_horse_id_horses_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_elements
    ADD CONSTRAINT billing_elements_horse_id_horses_id_fk FOREIGN KEY (horse_id) REFERENCES public.horses(id);


--
-- Name: billing_elements billing_elements_item_id_items_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_elements
    ADD CONSTRAINT billing_elements_item_id_items_id_fk FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: billing_elements billing_elements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_elements
    ADD CONSTRAINT billing_elements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: boxes boxes_stable_id_stables_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boxes
    ADD CONSTRAINT boxes_stable_id_stables_id_fk FOREIGN KEY (stable_id) REFERENCES public.stables(id);


--
-- Name: horse_movements horse_movements_agreement_id_livery_agreements_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.horse_movements
    ADD CONSTRAINT horse_movements_agreement_id_livery_agreements_id_fk FOREIGN KEY (agreement_id) REFERENCES public.livery_agreements(id);


--
-- Name: horse_movements horse_movements_horse_id_horses_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.horse_movements
    ADD CONSTRAINT horse_movements_horse_id_horses_id_fk FOREIGN KEY (horse_id) REFERENCES public.horses(id);


--
-- Name: horse_movements horse_movements_stablebox_id_boxes_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.horse_movements
    ADD CONSTRAINT horse_movements_stablebox_id_boxes_id_fk FOREIGN KEY (stablebox_id) REFERENCES public.boxes(id);


--
-- Name: horse_ownership horse_ownership_customer_id_customers_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.horse_ownership
    ADD CONSTRAINT horse_ownership_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: horse_ownership horse_ownership_horse_id_horses_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.horse_ownership
    ADD CONSTRAINT horse_ownership_horse_id_horses_id_fk FOREIGN KEY (horse_id) REFERENCES public.horses(id);


--
-- Name: invoice_validations invoice_validations_invoice_id_invoices_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_validations
    ADD CONSTRAINT invoice_validations_invoice_id_invoices_id_fk FOREIGN KEY (invoice_id) REFERENCES public.invoices(id);


--
-- Name: invoice_validations invoice_validations_user_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_validations
    ADD CONSTRAINT invoice_validations_user_id_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: invoices invoices_customer_id_customers_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: item_prices item_prices_item_id_items_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_prices
    ADD CONSTRAINT item_prices_item_id_items_id_fk FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: livery_agreements livery_agreements_box_id_boxes_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livery_agreements
    ADD CONSTRAINT livery_agreements_box_id_boxes_id_fk FOREIGN KEY (box_id) REFERENCES public.boxes(id);


--
-- Name: livery_agreements livery_agreements_customer_id_customers_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livery_agreements
    ADD CONSTRAINT livery_agreements_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: livery_agreements livery_agreements_item_id_items_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livery_agreements
    ADD CONSTRAINT livery_agreements_item_id_items_id_fk FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: monthly_billing_approvals monthly_billing_approvals_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_billing_approvals
    ADD CONSTRAINT monthly_billing_approvals_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: monthly_billing_approvals monthly_billing_approvals_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_billing_approvals
    ADD CONSTRAINT monthly_billing_approvals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 62SZQOmAb7MycA8mX4T4cmFmcwO4T6cSrqOHR177ztrbSjjHpqhaTEvlTpMsaqG

