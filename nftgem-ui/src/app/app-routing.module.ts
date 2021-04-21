import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ClaimsComponent } from './components/claims/claims.component';
import { FAQComponent } from './components/faq/faq.component';
import { StakingPoolsComponent } from './components/staking-pools/staking-pools.component';
import { GemsComponent } from './components/gems/gems.component';
import { GovernanceComponent } from './components/governance/governance.component';
import { SwapComponent } from './components/swap/swap.component';
import { HomeComponent } from './components/home/home.component';

const routes: Routes = [
  { path: 'pools', component: StakingPoolsComponent },
  { path: 'claims', component: ClaimsComponent },
  { path: 'gems', component: GemsComponent },
  { path: 'faq', component: FAQComponent },
  { path: 'governance', component: GovernanceComponent },
  { path: 'swap', component: SwapComponent },
  { path: 'home', component: HomeComponent },
  { path: '', redirectTo: '/home', pathMatch: 'full' },
];
@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
