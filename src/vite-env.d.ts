/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_CHAIN_ID: string
  readonly VITE_CHAIN_NAME: string
  readonly VITE_NFT_CONTRACT_ADDRESS: string
  readonly VITE_MFAC_SYSTEM_CONTRACT_ADDRESS: string
  readonly VITE_RPC_URL: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
declare module '*.vue' {
  import { DefineComponent } from 'vue';
  const component: DefineComponent<{}, {}, any>;
  export default component;
}