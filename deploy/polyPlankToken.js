require('dotenv').config();

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()


  await deploy('PolyPlankToken', {
    from: deployer,
    args: [process.env.POLYPLANK_DEV_WALLET],
    log: true,
    deterministicDeployment: false,
  })
}

module.exports.tags = ["PolyPlankToken", "NFT", "Dragon"];
