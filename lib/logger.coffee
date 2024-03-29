winston = require 'winston'

exports.logger = new winston.Logger {
    transports: [
        new winston.transports.Console { colorize: true }
        new winston.transports.File { filename: 'logs/hunter.log' }
    ]
}
