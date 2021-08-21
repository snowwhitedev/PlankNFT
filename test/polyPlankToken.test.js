const { expect } = require('chai');
const { ethers } = require('hardhat');
const { BigNumber } = ethers;

describe('PolyPlankTokenPolyPlankToken', function() {
  before(async function() {
    this.PolyPlank = await ethers.getContractFactory('PolyPlankToken');
    this.signers = await ethers.getSigners();
  })

  beforeEach(async function() {
    this.polyPlank = await this.PolyPlank.deploy(this.signers[0].address);
    this.buyingPrice = BigNumber.from(25).mul(BigNumber.from(10).pow(18));
  })

  it('Should be deployed with correct Name and Symbol', async function() {
    const name = await this.polyPlank.name();
    expect(name).to.equal('PolyPlank GEN1');

    const symbol = await this.polyPlank.symbol();
    expect(symbol).to.equal('POLYPLANKG1');
  })

  it("Should allow only owner to mint", async function() {
    const tokenURI = 'https://google.com';
    await expect(
      this.polyPlank.connect(this.signers[1])
        .mintPlank(tokenURI, { from: this.signers[1].address })
    ).to.be.revertedWith('Ownable: caller is not the owner');

    const salesRemainingBefore = await this.polyPlank.salesRemaining();
    await this.polyPlank.mintPlank(tokenURI);   
    const salesRemainingAfter = await this.polyPlank.salesRemaining();
    
    expect (BigNumber.from(salesRemainingBefore).add(1)).equal(BigNumber.from(salesRemainingAfter));
  })

  it('Should only promoter claim', async function() {
    const tokenURI = 'https://google.com';
    await this.polyPlank.mintPlank(tokenURI);

    await expect(
      this.polyPlank.connect(this.signers[1])
        .claimPromoter()
    ).to.be.revertedWith('Only promoter.');

    await this.polyPlank.addPromoter(this.signers[1].address);

    const tx = await this.polyPlank.connect(this.signers[1])
        .claimPromoter({ from: this.signers[1].address })
    
    const tokenId = (await tx.wait()).events[0].args.tokenId;
    const newOwner = await this.polyPlank.ownerOf(tokenId);
    expect(newOwner).to.equal(this.signers[1].address);
  })

  it('Should buy planks', async function() {
    const tokenURI = 'https://google.com';
    for(let ii = 0; ii < 5; ii++) {
      await this.polyPlank.mintPlank(tokenURI);
    }

    const desiredQuantity = 10;
    await expect(
      this.polyPlank.connect(this.signers[1])
        .buyPlanks(
          desiredQuantity,
          {
            from: this.signers[1].address,
            value: BigNumber.from(desiredQuantity).mul(this.buyingPrice)
          }
        )
    ).to.be.revertedWith("There aren't enough left to buy that many");

    for(let ii = 0; ii < 6; ii++) {
      await this.polyPlank.mintPlank(tokenURI);
    }

    const balanceBefore = await this.polyPlank.balanceOf(this.signers[1].address);
    await this.polyPlank.connect(this.signers[1])
        .buyPlanks(
          desiredQuantity,
          {
            from: this.signers[1].address,
            value: BigNumber.from(desiredQuantity).mul(this.buyingPrice)
          }
        )
   
    const balanceAfter = await this.polyPlank.balanceOf(this.signers[1].address);
    expect(balanceBefore.add(BigNumber.from(10))).to.equal(balanceAfter);
  })
})
