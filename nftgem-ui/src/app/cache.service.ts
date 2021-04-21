import { Injectable } from '@angular/core';
import { keccak256, pack } from "@ethersproject/solidity";



@Injectable({
  providedIn: 'root'
})
export class CacheService {

  static hash(obj: Record<string, unknown>, keys: []): string {
    return keccak256(
      ['string'],
      [pack(
        ['string'],
        [keys.map(k => obj[k]).join('')]
      )]
    );
  }

  static put(obj: any | any[], key: string): string {
    localStorage[key] = JSON.stringify(obj)
    return key;
  }

  static get(hash: string): any | any[] {
    const out = localStorage[hash];
    return out ? JSON.parse(out) : null;
  }

  static has(hash: string): boolean {
    return localStorage[hash] != null;

  }

  static del(hash: string): void {
    localStorage[hash] = null;

  }
}

