import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { PageHeaderComponent } from './components/page-header/page-header.component';
import { StakingPoolsComponent } from './components/staking-pools/staking-pools.component';
import { ClaimsComponent } from './components/claims/claims.component';
import { GemsComponent } from './components/gems/gems.component';
import { GemPoolComponent } from './components/gem-pool/gem-pool.component';
import { GemClaimComponent } from './components/gem-claim/gem-claim.component';
import { GemComponent } from './components/gem/gem.component';
import { SwapComponent } from './components/swap/swap.component';
import { FAQComponent } from './components/faq/faq.component';
import { GovernanceComponent } from './components/governance/governance.component';
import { SectionHeaderComponent } from './components/section-header/section-header.component';
import { GemListComponent } from './components/gem-list/gem-list.component';
import { HomeComponent } from './components/home/home.component';
import { ClaimListComponent } from './components/claim-list/claim-list.component';
import { PoolListComponent } from './components/pool-list/pool-list.component';
import { Web3ConnectButtonComponent } from './components/web3-connect-button/web3-connect-button.component';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { CommonModule } from '@angular/common';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { ToastrModule } from 'ngx-toastr';
import { NotConnectedPanelComponent } from './components/not-connected-panel/not-connected-panel.component';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import { FooterComponent } from './components/footer/footer.component';
import { ConvertGemComponent } from './components/convert-gem/convert-gem.component';
import { ConvertGovernanceComponent } from './components/convert-governance/convert-governance.component';

@NgModule({
  declarations: [
    AppComponent,
    PageHeaderComponent,
    StakingPoolsComponent,
    ClaimsComponent,
    GemsComponent,
    GemPoolComponent,
    GemClaimComponent,
    GemComponent,
    SwapComponent,
    FAQComponent,
    GovernanceComponent,
    SectionHeaderComponent,
    GemListComponent,
    ClaimListComponent,
    PoolListComponent,
    HomeComponent,
    Web3ConnectButtonComponent,
    NotConnectedPanelComponent,
    FooterComponent,
    ConvertGemComponent,
    ConvertGovernanceComponent
  ],
  imports: [
    BrowserModule,
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    AppRoutingModule,
    BrowserAnimationsModule, // required animations module
    ToastrModule.forRoot(), NgbModule // ToastrModule added
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
