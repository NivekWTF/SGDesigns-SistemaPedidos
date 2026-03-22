export interface CompanyInfo {
name: string
rfc: string
email: string
phone: string
address: string
}


export interface Header {
series: string
date: string
folio: string
company: CompanyInfo
logoDataUrl: string
}


export interface Client {
name: string
address: string
}


export interface Config {
taxRate: number
}


export interface ItemRow {
qty: number
description: string
unitPrice: number
applyTax: boolean
}


export interface QuoteState {
header: Header
client: Client
config: Config
items: ItemRow[]
notes: string
}